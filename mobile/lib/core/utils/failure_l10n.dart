import 'package:folia/core/error/result.dart';
import 'package:folia/l10n/generated/app_localizations.dart';

extension FailureL10n on Failure {
  String localized(AppLocalizations l) => switch (this) {
        NetworkFailure() => l.errorNetwork,
        AuthFailure() => l.errorSession,
        InvalidCredentialsFailure() => l.errorInvalidCredentials,
        ValidationFailure() => l.errorValidation,
        RateLimitedFailure() => l.errorRateLimited,
        NotFoundFailure() => l.errorNotFound,
        StorageFailure() => l.errorStorage,
        ServerFailure() => l.errorServer,
      };
}
