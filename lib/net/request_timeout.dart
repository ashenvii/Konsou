/// Request timeout. Without it a stalled connection holds its queue until
/// Windows drops the socket.
const requestTimeout = Duration(seconds: 30);
