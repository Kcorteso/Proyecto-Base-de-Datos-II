import psycopg2
from pymongo import MongoClient

conn = psycopg2.connect(
    host="localhost",
    database="marketplace",
    user="postgres",
    password="12345678"
)
cursor = conn.cursor()

mongo_client = MongoClient("mongodb://localhost:27017/")
db = mongo_client["MarketPlace(envios)"]

def evaluar_reembolso(id_orden):

    cursor.execute("""
        SELECT p.estado_pago, d.id_producto
        FROM pagos p
        JOIN orden o ON p.id_orden = o.id_orden
        JOIN detalle_orden d ON o.id_orden = d.id_orden
        WHERE o.id_orden = %s
        LIMIT 1
    """, (id_orden,))

    resultado = cursor.fetchone()

    if not resultado:
        return "Orden no encontrada"

    estado_pago, id_producto = resultado

    queja = db.quejas_reembolso.find_one({
        "id_producto_sql": id_producto
    })

    if not queja:
        return "No hay queja registrada"

    evidencia = queja.get("imagenes", [])

    if estado_pago != "aprobado":
        return " Pago no aprobado"

    if len(evidencia) > 0:
        return " Reembolso aprobado (evidencia encontrada)"
    else:
        return "Revisar manualmente (sin evidencia)"

if __name__ == "__main__":
    orden = int(input("Ingrese ID de la orden: "))
    resultado = evaluar_reembolso(orden)
    print(resultado)
    