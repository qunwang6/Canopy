/// Codable representation of Result.
///
/// Out of the box, Result is not Codable. When the success and error types are both codable,
/// we can have a proxy type for the Result.
///
/// This does not include conversion to/from the actual Result because we may want to
/// massage the types a bit. Conversion should be done at the sites of use.
enum CodableResult<T, E>: Codable where T: Codable, E: Error, E: Codable {
  case success(T)
  case failure(E)
}
