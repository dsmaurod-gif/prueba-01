const http = require("http");
const net = require("net");

const { APP_ENV, DB_HOST, DB_PORT } = process.env;

function responder(res, estado, datos) {
  res.writeHead(estado, {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*"
  });
  res.end(JSON.stringify(datos));
}

const server = http.createServer((req, res) => {
  if (req.url === "/") {
    return responder(res, 200, { servicio: "api", ambiente: APP_ENV, instancia: process.env.HOSTNAME });
  }

  if (req.url === "/db") {
    // Prueba de conexión TCP con la base de datos
    const socket = net.createConnection({ host: DB_HOST, port: Number(DB_PORT) });
    socket.setTimeout(2000);
    socket.on("connect", () => {
      socket.destroy();
      responder(res, 200, { bd: "conectado", host: DB_HOST });
    });
    socket.on("timeout", () => socket.destroy(new Error("tiempo de espera agotado")));
    socket.on("error", (err) => {
      socket.destroy();
      responder(res, 503, { bd: "sin conexion", error: err.message });
    });
    return;
  }

  responder(res, 404, { error: "ruta no encontrada" });
});

server.listen(3000, () => console.log(`api escuchando en el puerto 3000 (${APP_ENV})`));
