namespace Lilac.Validation;

public class ValidationException(string validationId, string message)
  : Exception($"{validationId}: {message}") {
  // Empty
}
