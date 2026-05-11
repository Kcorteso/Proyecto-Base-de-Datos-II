# Marketplace de Logística y Envíos

Proyecto académico enfocado en el desarrollo de una arquitectura híbrida utilizando PostgreSQL y MongoDB para la gestión de un marketplace de logística y envíos tipo Amazon o MercadoLibre.

---

# Integrantes

- Rafael Esteban Arango Castro
- Integrante 2
- Integrante 3
- Integrante 4

---

# Descripción del Proyecto

El sistema permite gestionar procesos relacionados con:

- Usuarios compradores y vendedores
- Órdenes de compra
- Pagos y transacciones
- Inventario físico
- Gestión de envíos
- Catálogo flexible de productos
- Seguimiento GPS en tiempo real
- Reseñas y evidencias multimedia
- Solicitudes de reembolso

El proyecto implementa una arquitectura híbrida:

- PostgreSQL → Datos transaccionales y consistentes
- MongoDB → Datos no estructurados y dinámicos

---

# Tecnologías Utilizadas

## PostgreSQL
Utilizado para manejar:

- Usuarios
- Órdenes
- Pagos
- Inventario
- Envíos
- Reembolsos

## MongoDB
Utilizado para manejar:

- Catálogo flexible de productos
- Reseñas con imágenes
- Tracking GPS
- Evidencias de reembolso

---

# Arquitectura del Proyecto

## PostgreSQL (Relacional)

Entidades principales:

- Usuarios
- Direcciones
- Productos
- Inventario
- Órdenes
- Detalle_Orden
- Pagos
- Envíos
- Historial_Envios
- Reembolsos

---

## MongoDB (Documental)

Colecciones principales:

- productos
- resenas
- tracking_envios
- quejas_reembolso

---

# Integración PostgreSQL + MongoDB

El sistema integra ambas bases de datos para procesos críticos como:

## Reembolsos

El sistema valida:

- Información del pago y la orden desde PostgreSQL
- Evidencias multimedia y comentarios desde MongoDB

Esto permite evaluar la viabilidad de un reembolso de forma más eficiente.

---

# Objetivos del Proyecto

- Diseñar un sistema híbrido SQL + NoSQL
- Implementar consistencia ACID en procesos críticos
- Manejar datos dinámicos mediante documentos
- Simular un marketplace moderno de logística

---

# Estado Actual

## Avance 1

- [x] Propuesta de dominio
- [x] Modelo entidad-relación
- [x] Modelo relacional
- [x] Modelo documental MongoDB
- [ ] Procedimientos almacenados
- [ ] Triggers
- [ ] Inserción de datos masivos

---

# Estructura del Repositorio

```bash
📁 marketplace-logistica
 ├── 📁 postgresql
 ├── 📁 mongodb
 ├── 📁 diagramas
 ├── README.md
