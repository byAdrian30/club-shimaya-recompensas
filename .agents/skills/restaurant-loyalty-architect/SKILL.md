---
name: restaurant-loyalty-architect
description: Especialista en diseno financiero, operativo y tecnico de programas de recompensas de doble via (Mapa de Ruta por visitas + Puntos por consumo) para restaurantes, vinculados al DNI y comprobantes electronicos (boletas/facturas). Usalo cuando el usuario pida estructurar propuestas de fidelizacion gastronomica, calcular el costo de premios sobre el margen (food cost y cashback), disenar bases de datos relacionales anti-duplicados por DNI, definir reglas antifraude en caja/POS o programar el sistema de consulta de puntos y ruta.
---
# Restaurant Loyalty Architect

Esta skill permite estructurar propuestas integrales, modelos financieros, bases de datos y flujos operativos para programas de fidelizacion de restaurantes basados en un sistema de doble via (frecuencia por visitas + volumen por consumo), integrados con la emision de comprobantes de pago y validados mediante documento de identidad (DNI).

## When to Use

- Cuando el usuario pida armar o estructurar una propuesta de programa de recompensas, fidelizacion o lealtad para su restaurante.
- Cuando se necesite disenar o ajustar un "Mapa de Ruta" (hitos por visita) combinado con acumulacion de puntos por monto consumido.
- Cuando se requiera calcular la rentabilidad de los premios (food cost de cortesias vs. porcentaje de cashback) para no canibalizar el margen del restaurante.
- Cuando el usuario solicite modelar la base de datos (SQL/Supabase), logica de backend o interfaz web de consulta cruzando el DNI del cliente con las boletas emitidas en el sistema POS.
- Cuando se busquen protocolos antifraude en caja para evitar el registro indebido de boletas o la duplicidad de clientes.

## Steps

### 1. Estructuracion de la Mecanica de Doble Via (Frecuencia + Volumen)

Al redactar o ajustar la propuesta comercial y operativa del programa, separa claramente los dos motores de incentivos para cubrir ambos perfiles de comensales:

1. **Via A - El Mapa de Ruta (Motor de Frecuencia):**
   - Disena un recorrido secuencial (de 10 a 12 estaciones/visitas) donde el cliente avanza **1 casilla por visita valida**.
   - Establece siempre un **consumo minimo por boleta** (ej. S/ 20.00 a S/ 30.00) para habilitar el avance de casilla y evitar compras marginales.
   - Escala las recompensas en hitos clave (ej. Visita 1, 3, 5, 8 y 10) priorizando productos de **alto valor percibido y bajo costo de insumo** (bebidas de la casa, entradas, multiplicadores de puntos o postres) y reservando el plato fuerte para la meta final.
   - Al completar la meta (Hito 10), ofrece un reinicio de ciclo hacia un nivel superior (ej. Nivel VIP con multiplicador permanente de 1.2x en puntos).

2. **Via B - El Banco de Puntos (Motor de Ticket Promedio):**
   - Convierte cada unidad monetaria pagada en puntos (ej. `1 Sol = 1 Punto`, redondeado al entero inferior).
   - Define una tabla o tasa de canje clara cuyo costo financiero no supere el **4% al 6%** del consumo acumulado (ej. `100 Puntos = S/ 5.00` en vales o productos equivalentes).
   - Garantiza la independencia de vias: canjear puntos nunca debe restar casillas ni retroceder al cliente en su Mapa de Ruta.

### 2. Blindaje Financiero y Control de Costos (Food Cost)

Cada vez que el usuario proponga premios o pida estructurar la propuesta economica, incluye una matriz de impacto financiero:

- **Techo presupuestal:** La suma del costo de los premios del Mapa de Ruta + el valor de canje de los puntos acumulados debe situarse entre el **5% y el 8% de las ventas brutas** generadas por ese cliente a lo largo del ciclo.
- **Calculo por costo de receta (Insumos), no precio de carta:** Evalua el costo real para el restaurante usando el costo de materia prima (Food Cost, tipicamente 28% a 35% del precio de venta) y no el precio al publico.
- **Tratamiento en comprobante (Normativa SUNAT):** Especifica que todo premio entregado debe registrarse en el POS como *Descuento Global* o *Transferencia Gratuita / Bonificacion* dentro de la boleta para cuadrar el descargo de kardex e inventario.

### 3. Arquitectura de Base de Datos y Candados Unicos

Cuando la propuesta incluya el diseno tecnico o de sistema, estructura el modelo relacional con cuatro entidades principales y tres candados de integridad:

- **Candado de Identidad (`dni UNIQUE`):** El DNI (8 digitos validados con API RENIEC/SUNAT) es la llave unica del cliente para impedir cuentas duplicadas.
- **Candado Transaccional (`comprobante_id UNIQUE`):** El numero de serie y correlativo de la boleta (ej. `B001-00045821`) se registra como clave unica en la tabla de movimientos para impedir que un mismo ticket sume puntos dos veces.
- **Tablas esenciales:**
  1. `clientes_fidelidad`: DNI, nombre, telefono, puntos disponibles, puntos historicos, hito actual del mapa, nivel de ciclo y fecha de ultima visita.
  2. `catalogo_hitos_mapa`: Numero de estacion, nombre del hito, premio desbloqueado, costo de insumo estimado y consumo minimo requerido.
  3. `registro_visitas_boletas`: ID unico de boleta (`Serie-Numero`), DNI asociado, fecha/hora, monto total, puntos generados, bandera booleana `avanzo_hito` y estado (`ACTIVA` / `ANULADA`).
  4. `recompensas_cliente`: Historial de premios desbloqueados por ruta o canjeados por puntos, estado (`DISPONIBLE`, `CANJEADO`, `VENCIDO`) y boleta en la que se efectuo el canje.

### 4. Protocolo Antifraude Operativo en Caja

Toda propuesta de implementacion debe contemplar las reglas de negocio para evitar fugas por parte del personal o manipulacion del sistema:

- **Asignacion nominal en tiempo real:** Prohibir la carga de puntos a boletas emitidas a "Clientes Varios" (`00000000`) horas despues de la venta. El DNI debe digitarse antes de cerrar el comprobante electronico.
- **Enfriamiento de Ruta (Cooldown de 1 visita por dia):** Si un cliente divide su cuenta en varias boletas el mismo dia, el sistema suma los puntos de todas las boletas (porque el ingreso economico es real), pero el campo `ultima_visita_fecha` bloquea el avance del Mapa de Ruta a **maximo 1 hito por dia calendario**.
- **Reversion por Nota de Credito o Anulacion:** Si una boleta pasa a estado `ANULADA`, un disparador descuenta automaticamente los puntos y revierte el hito ganado.

### 5. Formato de Entrega de la Propuesta

Cuando el usuario pida armar o presentar la propuesta (para socios, equipo de desarrollo o plan de negocio), entregala organizada en estos bloques:

1. **Resumen Ejecutivo y Propuesta de Valor:** Como funciona la doble via y por que incrementa tanto la frecuencia de visita como el ticket promedio.
2. **Diseno del Mapa de Ruta y Tabla de Puntos:** Tabla detallada de las estaciones, premios, requisitos de consumo y retorno financiero (% de costo para el restaurante).
3. **Flujo Operativo en el Restaurante:** Paso a paso desde que el cliente pide la cuenta y dicta su DNI hasta que consulta su progreso (via QR en la boleta impresa o web ligera sin apps).
4. **Requerimientos Tecnicos y Reglas Antifraude:** Esquema de base de datos y candados de seguridad con el facturador.

## Gotchas

- **No confundir precio de carta con costo del programa:** Si un plato cuesta S/ 40 en carta pero producirlo cuesta S/ 12 en insumos, evalua la sostenibilidad financiera del programa sobre los S/ 12 de costo directo, mostrando al cliente el beneficio percibido de S/ 40.
- **Evitar friccion en el registro:** Nunca propongas formularios largos en mesa ni obligar a descargar una app nativa en la primera visita. El registro inicial debe tomar 5 segundos en caja dictando solo el DNI (extrayendo nombres via consulta RENIEC) y opcionalmente el celular para WhatsApp.
- **Cuidar los guiones largos:** Mantener las tablas y esquemas limpios y faciles de exportar a documentos ejecutivos o codigo SQL.
