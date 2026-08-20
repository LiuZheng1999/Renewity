# Política de privacidad

**Fecha de entrada en vigor: 20 de agosto de 2026**

Hay una copia web igual al texto de la app en GitHub Pages:  
**https://maoxia-xiang.github.io/Renewity/privacy/**

Renewity (la «App») la proporciona el desarrollador de la App («nosotros»). Esta política explica cómo la App trata información sobre ti.

Está diseñada para que **los registros de suscripciones se queden en el dispositivo por defecto**. No operamos un servidor de inicio de sesión ni recogemos datos personales a través de la App para publicidad o perfiles.

Preguntas: **philiptrip1975@gmail.com**

## 1. Lo que no recogemos a través de la App

Salvo lo indicado, no pedimos cuenta con nosotros ni subimos a servidores que controlamos: nombre o correo (salvo que nos escribas), datos de suscripciones que introduces, identificadores publicitarios o SDK de analítica para rastrearte entre apps.

La App **no incluye SDK de anuncios de terceros ni herramientas de analítica de seguimiento entre apps**.

## 2. Información en el dispositivo

Suscripciones, categorías, notas, iconos, divisa, apariencia, notificaciones, bloqueo, etc. se guardan **en el dispositivo** (SwiftData / almacenamiento del sistema). Sirven para mostrar y gestionar, totales, aviso local el día anterior y resumen de widgets. Desinstalar suele borrar lo que solo está en el dispositivo y no hayas copiado a otro sitio.

## 3. App Group y widgets

La App y los widgets comparten `group.Maoxia-Xiang.Renewity`. La instantánea de visualización permanece en el dispositivo.

## 4. Copia iCloud opcional

Con Pro y la copia iCloud activada, un archivo va a **tu** iCloud Drive (contenedor `iCloud.Maoxia-Xiang.Renewity`), bajo tu cuenta de Apple y las políticas de iCloud de Apple. No podemos iniciar sesión en tu cuenta. Los JSON exportados son tu responsabilidad.

## 5. Notificaciones

Los avisos son **notificaciones locales**, creadas en el dispositivo, no subidas a nuestros servidores para enviar el recordatorio.

## 6. Face ID, Touch ID y código

El bloqueo usa LocalAuthentication. Las plantillas biométricas las guarda el sistema en el área segura. **No recogemos ni subimos datos de Face ID ni huellas.**

## 7. Compras

Las compras Pro van por StoreKit / App Store. Apple procesa pago y recibos. Podemos saber en el dispositivo si hay una compra activa, pero **no recibimos el número de tarjeta completo ni la contraseña de la cuenta de Apple**.

## 8. Peticiones de red

El dispositivo habla directamente con el servicio, no con una base de usuarios nuestra.

Si la divisa de visualización difiere de la de referencia local, pueden pedirse tipos a una API pública (actualmente `open.er-api.com`) para una estimación, no una oferta de cambio.

Al «Elegir un servicio» puede consultarse la API del App Store / iTunes, servicios públicos de dominio (p. ej. Clearbit) y CDN de iconos (icon.horse, unavatar.io, favicone.com, según las peticiones). **Las palabras o dominios que escribas** pueden enviarse. No pongas contraseñas ni números de tarjeta. Los resultados no son una recomendación.

La copia iCloud sigue la política de privacidad de Apple.

## 9. Lo que nos envías

Los correos in-app van a **philiptrip1975@gmail.com**. Los usamos para responder y los borramos cuando ya no hacen falta, salvo obligación legal.

## 10. Analítica, publicidad y seguimiento

Sin anuncios de terceros, sin SDK de analítica para perfiles de marketing con tus suscripciones, sin seguimiento entre apps de otras empresas. Diagnósticos o estadísticas del App Store hacia Apple, si los permites, se rigen por Apple.

## 11. Menores

La App no está dirigida a menores de 13 años y no recogemos a sabiendas sus datos. Si crees que ha habido un error, contáctanos.

## 12. Conservación y supresión

Datos del dispositivo: al borrar en la App o desinstalar. Copia iCloud: hasta sobrescribir, borrar en iCloud Drive o desactivar. JSON exportado: según dónde lo guardes.

## 13. Seguridad

Almacenamiento local por defecto, bloqueo opcional, canales de Apple. Ningún almacenamiento es perfectamente seguro.

## 14. Tus derechos

Según dónde vivas (RGPD, CCPA, etc.) puedes tener derechos de acceso, rectificación, supresión, exportación, limitación u oposición. La mayoría de los datos están en el dispositivo o en tu iCloud. Para correos de soporte respondemos en el plazo legal.

## 15. Tratamiento internacional

Tipos de cambio, búsqueda e iconos pueden tratarse en otros países. En el EEE, Reino Unido u otras regiones, usar esas funciones opcionales implica que comprendes ese tratamiento.

## 16. Cambios

Las actualizaciones aparecen en la App con nueva fecha. Si un cambio afecta de forma sustancial a tus derechos, daremos un aviso razonable.

## 17. Contacto

Solicitudes de privacidad: **philiptrip1975@gmail.com**

Incluye «Política de privacidad» en el asunto.

## Nota adicional (20 de agosto de 2026)

- La app requiere iOS 18 o posterior.
- **No hay sincronización CloudKit en vivo** de la base de datos. La copia Pro se guarda en tu iCloud Drive.
- Los recordatorios son notificaciones locales. La app programa varias fechas futuras y actualiza la cola al abrirla. Si no la abres durante mucho tiempo, los avisos posteriores pueden detenerse por el límite del sistema.
- Incluye Privacy Manifest y no hace seguimiento entre apps.
