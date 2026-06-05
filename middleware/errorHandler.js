export default function errorHandler(err, req, res, next) {
  const status = err.status ?? 500;
  res.status(status).json({
    error: { message: err.message, status },
  });
}
