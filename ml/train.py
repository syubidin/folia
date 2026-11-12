import json
import pathlib

import numpy as np
import tensorflow as tf

DATA, SIZE, BATCH, SEED = "dataset", 224, 32, 42
AUTOTUNE = tf.data.AUTOTUNE
L = tf.keras.layers

common = dict(
    seed=SEED,
    image_size=(SIZE, SIZE),
    batch_size=BATCH,
    label_mode="categorical",
    validation_split=0.15,
)
train = tf.keras.utils.image_dataset_from_directory(DATA, subset="training", **common)
val = tf.keras.utils.image_dataset_from_directory(DATA, subset="validation", **common)
classes = train.class_names
n = len(classes)

counts = [len(list(pathlib.Path(DATA, c).glob("*.jpg"))) for c in classes]
weights = {i: sum(counts) / (n * max(c, 1)) for i, c in enumerate(counts)}

aug = tf.keras.Sequential([
    L.RandomFlip("horizontal"),
    L.RandomRotation(0.08),
    L.RandomZoom(0.15),
    L.RandomContrast(0.15),
    L.RandomBrightness(0.15, value_range=(0, 255)),
])
train_ds = train.map(
    lambda x, y: (aug(x, training=True), y), num_parallel_calls=AUTOTUNE
).prefetch(AUTOTUNE)
val_ds = val.prefetch(AUTOTUNE)

base = tf.keras.applications.MobileNetV3Large(
    input_shape=(SIZE, SIZE, 3), include_top=False, weights="imagenet"
)
base.trainable = False
inputs = tf.keras.Input((SIZE, SIZE, 3))
x = base(inputs, training=False)
x = L.GlobalAveragePooling2D()(x)
x = L.Dropout(0.3)(x)
outputs = L.Dense(n, activation="softmax")(x)
model = tf.keras.Model(inputs, outputs)


def compile_with(lr):
    model.compile(
        optimizer=tf.keras.optimizers.Adam(lr),
        loss=tf.keras.losses.CategoricalCrossentropy(label_smoothing=0.1),
        metrics=["accuracy", tf.keras.metrics.TopKCategoricalAccuracy(3, name="top3")],
    )


stop = tf.keras.callbacks.EarlyStopping(
    monitor="val_accuracy", patience=3, restore_best_weights=True
)
compile_with(1e-3)
model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=8,
    class_weight=weights,
    callbacks=[stop],
)

base.trainable = True
for layer in base.layers[:-40]:
    layer.trainable = False
for layer in base.layers:
    if isinstance(layer, L.BatchNormalization):
        layer.trainable = False
compile_with(2e-5)
model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=12,
    class_weight=weights,
    callbacks=[stop],
)

probs, truth = [], []
for xb, yb in val_ds:
    probs.append(model.predict(xb, verbose=0))
    truth.append(np.argmax(yb.numpy(), axis=1))
probs, truth = np.concatenate(probs), np.concatenate(truth)
order = np.argsort(-probs, axis=1)
rows = np.arange(len(probs))
p1, p2 = probs[rows, order[:, 0]], probs[rows, order[:, 1]]
correct = order[:, 0] == truth
top1 = correct.mean()
top3 = np.mean([t in o[:3] for t, o in zip(truth, order)])
print(f"val top1={top1:.3f} top3={top3:.3f}")

best = None
for accept in np.arange(0.5, 0.96, 0.05):
    for margin in np.arange(0.1, 0.61, 0.05):
        ok = (p1 >= accept) & ((p1 - p2) >= margin)
        if ok.mean() < 0.3:
            continue
        precision = correct[ok].mean()
        if precision >= 0.90 and (best is None or ok.mean() > best[2]):
            best = (float(accept), float(margin), float(ok.mean()), float(precision))
accept, margin = (best[0], best[1]) if best else (0.80, 0.30)
print("ambang:", best)

print("kelas terlemah (recall):")
recall = [
    (classes[c], correct[truth == c].mean()) for c in range(n) if (truth == c).any()
]
for name, r in sorted(recall, key=lambda t: t[1])[:10]:
    print(f"  {name}: {r:.2f}")

conv = tf.lite.TFLiteConverter.from_keras_model(model)
conv.optimizations = [tf.lite.Optimize.DEFAULT]
conv.target_spec.supported_types = [tf.float16]
tflite = conv.convert()
pathlib.Path("plants.tflite").write_bytes(tflite)
pathlib.Path("labels.txt").write_text("\n".join(classes) + "\n")
pathlib.Path("model_meta.json").write_text(
    json.dumps(
        {
            "version": "2026.11.1",
            "inputSize": SIZE,
            "classes": n,
            "accept": round(accept, 2),
            "minMargin": round(margin, 2),
            "reject": 0.10,
            "valTop1": round(float(top1), 3),
            "valTop3": round(float(top3), 3),
        },
        indent=2,
    )
)

itp = tf.lite.Interpreter(model_content=tflite)
itp.allocate_tensors()
inp, out = itp.get_input_details()[0], itp.get_output_details()[0]
xb, _ = next(iter(val_ds))
agree = 0
for i in range(len(xb)):
    itp.set_tensor(inp["index"], xb[i : i + 1].numpy().astype("float32"))
    itp.invoke()
    agree += int(
        np.argmax(itp.get_tensor(out["index"]))
        == np.argmax(model.predict(xb[i : i + 1], verbose=0))
    )
print(f"kesesuaian TFLite vs Keras: {agree}/{len(xb)}")
print(f"ukuran model: {len(tflite)/1e6:.1f} MB")