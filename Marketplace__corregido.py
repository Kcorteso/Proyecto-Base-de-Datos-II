import psycopg2
from pymongo import MongoClient

# =========================
# CONEXIÓN POSTGRESQL
# =========================
conn = psycopg2.connect(
    host="localhost",
    database="marketplace",
    user="postgres",
    password="12345678"
)

cursor = conn.cursor()

# =========================
# CONEXIÓN MONGO
# =========================
mongo_client = MongoClient("mongodb://localhost:27017/")
db = mongo_client["MarketPlace(envios)"]

# =====================================================
# 1. EVALUAR REEMBOLSO
# =====================================================
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

    # Buscar queja en Mongo
    queja = db.quejas_reembolso.find_one({
        "id_producto_sql": id_producto
    })

    if not queja:
        return " No hay queja registrada"

    evidencia = queja.get("imagenes", [])

    if estado_pago != "aprobado":
        return " Pago no aprobado"

    if len(evidencia) > 0:
        return "Rembolso aprobado (evidencia encontrada)"
    else:
        return "Revisar manualmente (sin evidencia)"

# =====================================================
# 2. PRODUCTOS CON STOCK CRÍTICO
# =====================================================
def productos_stock_critico():

    cursor.execute("""
        SELECT p.nombre, i.stock_actual, i.stock_minimo
        FROM inventario i
        JOIN producto p ON i.id_producto = p.id_producto
        WHERE i.stock_actual <= i.stock_minimo
    """)

    resultados = cursor.fetchall()

    print("\n===== STOCK CRÍTICO =====\n")

    if not resultados:
        print("No hay productos críticos")
        return

    for producto in resultados:
        print(
            f"Producto: {producto[0]} | "
            f"Stock Actual: {producto[1]} | "
            f"Stock Mínimo: {producto[2]}"
        )

# =====================================================
# 3. TRACKING DE ENVÍO
# =====================================================
def mostrar_tracking(id_envio):

    tracking = db.tracking_envios.find_one({
        "id_envio_sql": id_envio
    })

    print("\n===== TRACKING ENVÍO =====\n")

    if not tracking:
        print("No hay tracking disponible")
        return
    
    # =========================
    # ESTADO ACTUAL
    # =========================
    estado = tracking.get("estado_actual", "Sin estado")
    print(f"Estado actual: {estado}\n")

    # =========================
    # VEHÍCULO
    # =========================
    vehiculo = tracking.get("vehiculo", {})

    print(
        f"Vehículo: {vehiculo.get('tipo', 'N/A')} | "
        f"Placa: {vehiculo.get('placa', 'N/A')}\n"
    )

    # =========================
    # RUTA
    # =========================
    print("===== RUTA =====\n")

    ruta = tracking.get("ruta", [])

    if not ruta:
       print("No hay puntos de ruta registrados")
       return


    for punto in ruta:
        print(
            f"Latitud: {punto['latitud']} | "
            f"Longitud: {punto['longitud']} | "
            f"Fecha: {punto['fecha']}"
            
        )

# =====================================================
# 4. PRODUCTOS CON MÁS QUEJAS
# =====================================================
def productos_con_quejas():

    pipeline = [
        {
            "$group": {
                "_id": "$id_producto_sql",
                "total_quejas": {"$sum": 1}
            }
        },
        {
            "$sort": {"total_quejas": -1}
        }
    ]

    resultados = db.quejas_reembolso.aggregate(pipeline)

    print("\n===== PRODUCTOS CON MÁS QUEJAS =====\n")

    for r in resultados:
        print(
            f"Producto ID: {r['_id']} | "
            f"Quejas: {r['total_quejas']}"
        )

# =====================================================
# MENÚ PRINCIPAL
# =====================================================
while True:

    print("\n==============================")
    print("   MARKETPLACE LOGÍSTICO")
    print("==============================")
    print("1. Evaluar reembolso")
    print("2. Ver stock crítico")
    print("3. Ver tracking envío")
    print("4. Productos con más quejas")
    print("5. Salir")

    opcion = input("\nSeleccione una opción: ")

    # ===================================
    # OPCIÓN 1
    # ===================================
    if opcion == "1":

        orden = int(input("Ingrese ID de la orden: "))
        resultado = evaluar_reembolso(orden)

        print("\nRESULTADO:")
        print(resultado)

    # ===================================
    # OPCIÓN 2
    # ===================================
    elif opcion == "2":

        productos_stock_critico()

    # ===================================
    # OPCIÓN 3
    # ===================================
    elif opcion == "3":
        envio = int(input("Ingrese ID del envío: "))
        mostrar_tracking(envio)

    # ===================================
    # OPCIÓN 4
    # ===================================
    elif opcion == "4":

        productos_con_quejas()

    # ===================================
    # OPCIÓN 5
    # ===================================
    elif opcion == "5":

        print("\nSaliendo del sistema...")
        break

    else:
        print("\n Opción inválida")