/// Web build: there is no `HttpOverrides` concept in the browser, and
/// certificate trust is controlled entirely by the browser itself.
/// This is a no-op on web.
void setHttpOverrides() {
  // Nothing to do on web.
}