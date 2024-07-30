# Desafío Técnico DevSecOps/SRE

## Objetivo
Desarrollar un sistema en la nube para ingestar, almacenar y exponer datos mediante el uso de IaC y despliegue con flujos CI/CD. Hacer pruebas de calidad, monitoreo y alertas para asegurar y monitorear la salud del sistema.

## Parte 1:Infraestructura e IaC

### 1. Identificar la infraestructura necesaria para ingestar, almacenar y exponer datos:
Por dominio y preferencia se creará la infraestructura en *GCP*.

#### 1.a. Utilizar el esquema Pub/Sub (no confundir con servicio Pub/Sub de Google) para ingesta de datos:
- Con el objetivo de utilizar el esquema Pub/Sub para la ingesta de datos determiné utilizar el servicio de **Pub/Sub de google** ya que se adapta perfectamente al esquema al cumplir las funciones message broker junto con el soporte para publishers y subscribers.
- Con el fin de mantener simplicidad se define como publisher a la misma API el cual tendrá un endpoint llamado ["/ingestData"](https://github.com/ronaldramrod93/latam-challenge/blob/57e4d24804aef96b923c1b16410e39ae9de4226d/app.py#L17C1-L26C67) para la ingesta de data, la cual publicará esta misma a un topico de Pub/Sub.
- Tambien por simplicidad la subscripción utilizará **Bigquery subscription** para insertar los mensajes recibidos a una de tabla Biguery directamente.

#### 1.b. Base de datos para el almacenamiento enfocado en analítica de datos
- Se utilizará **Bigquery** ya que es serverless, tiene un integración perfecta con el servicio **Pub/Sub**, además de que es ideal para analítica de datos a gran escala.

#### 1.c. Endpoint HTTP para servir parte de los datos almacenados
- Se utilizará **Cloud Run** para exponer el endpoint HTTP.
- Se escogió Cloud Run ya que es **serverless** y por la simplicidad en el despliegue de una aplicación asi como nuevas versiones.

### 2. (Opcional) Deployar infraestructura mediante Terraform de la manera que más te acomode. Incluir código fuente Terraform. No requiere pipeline CI/CD
- se creó la infraestructura utilizando **Terraform** y se dejó el código fuente en la carpeta ["iac"](https://github.com/ronaldramrod93/latam-challenge/tree/main/iac).
- Se sigue una **convención de nombres** para la creación de recursos "challenge-latam-***RESOURCE***-***ENVIRONMENT***"
- El estado de los archivos terraform se guardan en un **backend remoto en la nube** del tipo [GCS](https://github.com/ronaldramrod93/latam-challenge/blob/main/iac/config.tf).
- En la creación de la subscripción se agregaron las variables **ack_deadline_seconds** para asegurar reintentos ante posibles fallos en el procesamiento del mensaje recibido y **message_retention_duration** para permitir un reprocesamiento de mensajes en acknowledge despues de un fallo en los subscribers.
- Se recomienda utilizar también **dead-letter topic** para asegurar un análisis eficiente de errores que podrían estar dándose en nuestro sistema.
- Para las tablas de Bigquery se recomienda utilizar **particionamiento** y **clustering** para mejorar el performance de las queries y reducción de costos.
- Por simplicidad no se utilizó **módulos** pero es recomendable por un tema de orden y poder ser reutilizados.

## Parte 2: Aplicaciones y flujo CI/CD

### 1. API HTTP: Levantar un endpoint HTTP con lógica que lea datos de base de datos y los exponga al recibir una petición GET
- Se creó una aplicación con **python** la cual se conecta a **Bigquery** al desplegar.
- Se creó un endpoint llamado ["/getData"](https://github.com/ronaldramrod93/latam-challenge/blob/57e4d24804aef96b923c1b16410e39ae9de4226d/app.py#L29C1-L43C30) el cual al ser consumido primero construye una query la cual es ejecutada usando el cliente de bigquery para finalmente parsear la respuesta a JSON y entregarla.
- Con el objetivo de mantenerlo simple, este endpoint construye una query simple la cual define un "LIMIT 10".
- A continuación se deja un ejemplo de uso de dicho endpoint:

![alt text](https://github.com/ronaldramrod93/latam-challenge/blob/main/docs/getData.png)

### 2. Deployar API HTTP en la nube mediante CI/CD a tu elección. Flujo CI/CD y ejecuciones deben estar visibles en el repositorio git.
- Para el flujo CI/CD se utilizará **github action**, el workflow creado puede verse [aquí](https://github.com/ronaldramrod93/latam-challenge/blob/main/.github/workflows/ci-cd.yml) y las ejecuciones [aquí](https://github.com/ronaldramrod93/latam-challenge/actions).
- Se usa **gitflow** como flujo de trabajo pero no se considera la rama "release" ya que no es conveniente para este desafío.
- Se configura la **protección de rama** para la rama main y develop donde se requiere un PR antes de hacer merge con ramas del tipo feature o fix, asi como pasar OK los checks de estado.
- Se crearon **action secrets** para los datos sensibles como credenciales y **action variables** para hacer el pipeline parametrizable y poder ser rutilizados.
- Se configuró el pipeline CI/CD para que solo se ejecute en las acciones de push y pull request para la rama develop, con esto se logra asegurar la ejecución del pipeline y confirmar que sea exítoso antes que un nuevo cambio quiera integrarse, asi mismo se ignoró cambios por parte de las carpetas "iac" y "docs", ya que no son parte del código.
- Se filtró los pasos de **Despliegue Continuo** (CD) para ramas diferentes a develop.
- Sobre el flujo CI/CD de cada paso:
    - Se configuró los pasos iniciales "lint" y "test" (test unitarios) para que se hagan en **paralelo** ya que no son dependientes, aumentando la **velocidad** de ejecución.
    - El paso build depende de "lint" y "test" y el paso "deploy" depende de "build"

![alt text](https://github.com/ronaldramrod93/latam-challenge/blob/main/docs/cicd.png)

- Las mejoras a implementar a este CI/CD son:
    - Agregar un paso para el versionamiento de código usando **versionamiento semántico**.
    - Agregar un paso para la creación de un **tag** en el repositorio si todo termina exitosamente en el CI/CD de la rama develop.
    - Crear un workflow para la **promoción de la versión imagen** a producción usando el tag creado cuando se haga el merge a la rama main.

### 3. (Opcional) Ingesta: Agregar suscripción al sistema Pub/Sub con lógica para ingresar los datos recibidos a la base de datos. El objetivo es que los mensajes recibidos en un tópico se guarden en la base de datos. No requiere CI/CD.
- Como se mencionó para ingresar los datos se utilizará **Bigquery subscription** por la simplicidad en su implementacion y por que para este contexto no se pide ninguna transformación de la data antes del almacenado.
- ¿Cómo funciona? 
    - La creación de la Bigquery subscription se hace en la subscripcion donde se define la tabla de bigquery y otros parametros para la configuración del guardado.
    - Bigquery subscription automáticamente ingresa los datos utilizando la **API de escritura de Bigquery**, la cual le devuelve un estado de OK o ERROR.
    - Un OK convierte el mensaje "ACKNOWLEDGE", y un mensaje ERROR indica un reenvío.
- Si en el proceso de almacenamiento se requiere transformar la data entonces se recomienda algún subscriber como **Dataflow**.
- Como se mencionó líneas de arriba para el envío de mensajes a Pub/Sub se utiliza el endpoint "/ingestData", a continuación se deja un ejemplo de uso de dicho endpoint:

![alt text](https://github.com/ronaldramrod93/latam-challenge/blob/main/docs/ingestData.png)

### 4. Incluye un diagrama de arquitectura con la infraestructura del punto 1.1 y su interacción con los servicios/aplicaciones que demuestra el proceso end-to-end de ingesta hasta el consumo por la API HTTP

![alt text](https://github.com/ronaldramrod93/latam-challenge/blob/main/docs/diagram.png)

## Parte 3: Pruebas de Integración y Puntos Críticos de Calidad

### 1. Implementa en el flujo CI/CD en test de integración que verifique que la API efectivamente está exponiendo los datos de la base de datos. Argumenta.
- Se implementó el test de integración usando las librerías **pytest** y **request**. El código puede ser visto [aquí](https://github.com/ronaldramrod93/latam-challenge/blob/main/test_integration.py).
- El test de integración verifica que la API esta exponiendo datos con los siguientes puntos:
    - Verifica que el código de respuesta sea 200.
    - Verifica que se reciba una lista y que tenga elementos.
    - Verifica que el cuerpo de la respuesta tenga los parametros obligatorios.

### 2. Proponer otras pruebas de integración que validen que el sistema está funcionando correctamente y cómo se implementarían.
- Verificar el tiempo de respuesta sea menor o igual al promedio entregado al cliente.
   - Fragmento de código:
    ```python 
    import time
    #here goes more useful libraries
    def test_response_time(self):
        start_time = time.time()
        # Here goes to call endpoint with a incorrect request
        end_time = time.time()
        response_time = end_time - start_time
        self.assertTrue(response_time < 1, f"Response time exceeded threshold: {response_time}")
    ```

- Verificar los códigos de respuesta de error entregados sean los esperados. La forma de implementarlo es muy parecida al test de integración implementado solamente que se debe verificar código de error y cuerpo de la respuesta.

### 3. Identificar posibles puntos críticos del sistema (a nivel de fallo o performance) diferentes al punto anterior y proponer formas de testearlos o medirlos (no implementar)
- **Consumo de personas no autorizadas** exponiendo datos sensibles. Se podría medir revisando en los logs que las IPs mostradas están permitidas para consumir la API.
- Ataques de **SQL injection**. Se podría testear con pruebas de integración simulando un ataque.
- **Sobrecarga** de peticiones a la API ocasionando un alto costo y baja performance. Realizar pruebas de carga para validar el comportamiento de la API.

### 4. Proponer cómo robustecer técnicamente el sistema para compensar o solucionar dichos puntos críticos
- Aplicar **autenticación en dos fases (2FA)** con servicios como OKTA y autorización a base de roles a nuestra API.
- Utilizar **queries parametrizados** antes de enviarlas a ejecutar a Bigquery.
- Implementar un **rate limit** a nuestra aplicación para solo soportar ciertas cantidad de peticiones por cierto tiempo sino devolver un error `429 Too Many Requests`

## Parte 4: Métricas y Monitoreo

### 1. Proponer 3 métricas (además de las básicas CPU/RAM/DISK USAGE) críticas para entender la salud y rendimiento del sistema end-to-end
- **Error:** Medir la cantidad y tipo de peticiones con error (5xx o 4xx) así como tambien respuestas 200 pero con contenido erróneo.
- **Latencia:** Medir el tiempo de respuesta del sistema end-to-end asi como las interacciones internas (API con base de datos).
- **Tráfico:** Peticiones por segundo.

### 2. Proponer una herramienta de visualización y describe textualmente qué métricas mostraría, y cómo esta información nos permitiría entender la salud del sistema para tomar decisiones estratégicas
- Por experiencia y conocimiento para la API propongo **Datadog** ya que es una herramienta de monitoreo completa la cual nos podrá ayudar a recolectar **logs** y **trazas** donde se incluye errores, latencia y número de peticiones.
- Para la infraestructura como Pub/Sub y Bigquery propongo utilizar dashboard personalizados desde el servicio de **Monitoring de Google Cloud**.
- Las principales métricas a mostrar serían los mencionado en el punto anterior:
    - **Ratio de errores:** Nos permitirá saber la cantidad y tipos de errores que tiene nuestro sistema, asi mismo esta información nos 
    permitirá facilmente tomar la decisión de que error priorizar para resolver en base a la cantidad o tipo. Ejemplo: HTTP error, log error.
    - **Latencia:** Esta métrica me permitirá detectar cuellos de botella y componentes trabajando con bajo rendimiento, lo cual podria derivar a optimizar código python o queries, asi como aplicar por ejemplo particionamiento o clustering a nuestra tabla en Bigquery. Ejemplo: Tiempo que demora un mensaje en pasar a estado "acknowledge", tiempo de respuesta al publicar o ejecutar query a bigquery table.
    - **Tráfico:** Está metrica nos ayuda a identificar patrones de tráfico alto y bajos lo cual nos permitirá estar preparados para altos periodos de demanda al sistema. Ejemplo: Número de mensajes publicados y extraídos por segundo, Peticiones HTTP por segundo.

### 3. Describe a grandes rasgos cómo sería la implementación de esta herramienta en la nube y cómo esta recolectaría las métricas del sistema
- Para la API, el agente de datadog puede ser integrado via Dockerfile y con variables de entorno en el despliegue de la aplicación a cloud run. La recolección de logs es automática pero la recolección de trazas se debe setear las siguiente variable de entorno: `DD_TRACE_ENABLED=true`
- Para la implementación en la nube puede crearse manualmente o via terraform y utilizar las métricas ya integradas en Google Cloud.

### 4. Describe cómo cambiará la visualización si escalamos la solución a 50 sistemas similares y qué otras métricas o formas de visualización nos permite desbloquear este escalamiento.
- Si se da un escalamiento a 50 sistemas deberíamos **unificar** los diferentes dashboards en uno solo con la posibilidad de **entrar a detalle** en recursos en específico.
- Se deberían considerar agregar métricas que sean más genéricas como por ejemplo **Appdex** (satisfacción del usuario) y enfatizar métricas que tengan relación directa con la facturación. 

### 5. Comenta qué dificultades o limitaciones podrían surgir a nivel de observabilidad de los sistemas de no abordarse correctamente el problema de escalabilidad
- Dificultad a la hora de hacer **troubleshooting**.
- **Costos excesivos** en la infraestructura.
- **Degradación** del servicio.

## Parte 5: Alertas y SRE (Opcional)
### 1. Define específicamente qué reglas o umbrales utilizarías para las métricas propuestas, de manera que se disparan alertas al equipo al decaer la performance del sistema. Argumenta.
- **Latencia:** Utilizaría 2 tipos de umbrales basandome en el SLO definido para los tiempos de respuesta.
    - Ejemplo: SLO = 95% de peticiones en menos de 2 segundos, entonces
        - Se gatilla una alerta de advertencia cuando el 95% de peticiones están sobre los 1.5 segundos.
        - Se gatilla una alerta crítica cuando el 95% de peticiones están sobre los 1.8 segundos.
- **Tráfico:** Se debe definir en base al histórico que se considera un tráfico "normal" y en base a eso se definirán 2 tipos de umbrales.
    - Ejemplo: 
        - Se gatilla una alerta de advertencia cuando existe un 20% más del tráfico normal.
        - Se gatilla una alerta crítica cuando existe un 50% más del tráfico normal.
- **Error:** Se debe definir un SLO para el porcentaje de error aceptable por día, hora o minuto.
    - Ejemplo: SLO = < 2% de error por día.
        - Se gatilla una alerta de advertencia cuando existe un porcentage de error mayor al 1%
        - Se gatilla una alerta crítica cuando existe un porcentage de error mayor al 1.5%
### 2. Define métricas SLIs para los servicios del sistema y un SLO para cada uno de los SLIs. Argumenta por qué escogiste esos SLIs/SLOs y por qué desechaste otras métricas para utilizarlas dentro de la definición de SLIs.
Los SLIs son medidas cuantitativas de un aspecto específico de un sistema y los SLOs son los valores objetivo para el SLI que define un rendimiento aceptable del sistema. Se definen las siguientes SLIs/SLOs:

- **Disponibilidad:** Asegura que el servicio este operativo y accesible.
    - SLI: Porcentaje de tiempo que el servicio esta operativo y puede procesar peticiones (Disponibilidad).
    - SLO: 99.95% de disponibilidad por mes.

- **Latencia:** Asegura tiempo de respuesta aceptables.
    - SLI: Tiempo que toma una petición exitosas desde que se recibe al sistema hasta que se retorna un respuesta.
    - SLO: Percentil 95 del tiempo de respuesta < 1 segundo.

- **Ratio de error:** Garantiza confiabilidad de uso del sistema al usuario.
    - SLI: Porcentaje de peticiones que resultaron en error.
    - SLO: Ratio de error < 1% por mes.

- **Rendimiento:** Aseguro soportar la cantidad de peticiones aceptadas y evita degradación del servicio.
    - SLI: Cantidad de peticiones procesadas satisfactoriamente por segundo.
    - SLO: 1000 peticiones por segundo.

Se descartan las siguiente métricas:
- **Tiempo de respuesta promedio** ya que no el promedio no es un valor preciso para los tiempos que el usuario pueda experimentar.
- **Cantidad de peticiones procesadas** ya que incluye peticiones erróneas ya sea por parte del cliente o del sistema.
- **Tiempo que toma una petición end-to-end** ya que incluye peticiones erróneas ya sea por parte del cliente o del sistema.