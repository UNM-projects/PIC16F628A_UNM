Este proyecto fue realizado en el marco de la materia Técnicas Digitales II de la 
Universidad Nacional de Moreno. Dicho proyecto fue hecho por la alumna:

        - Clos, Ana María

- INTRODUCCIÓN:

El proyecto original consistio en estos pasos: 

Un pic transmisor envia 8 bits de datos y un bit de paridad y espera una confirmacion
para transmitir nuevamente.

Un pic receptor lee la informacion y calcula el sindrome de error. Si no hubo error, 
almacena el byte recibido y envia un uno al transmisor si hubo error, envia un cero al
transmisor según el dato recibido, el transmisor envia un nuevo dato, o reenvia el mismo.
 
La comunicación finaliza al recibir un carácter ETB (End of Transmition Block)
El receptor muestra en un display de siete segmentos los caracteres recibidos.

- ACLARACIÓN:

Debido a que el receptor tiene un buffer con capacidad de almacenar dos bytes, recien 
despues de que el transmisor envia el tercero, el receptor puede utilizar el primero.

Este comportamiento del microcontrolador no permite llevar a cabo el proyecto original.

- PROYECTO FINAL:

El transmisor envia continuamente un conjunto de caracteres que finalizan con un ETB (0x17).
Cada byte se envia con un 9no. bit de paridad.

El receptor almacena los caracteres recibidos y calcula el sindrome de error. Si hay error
se pone uno en una bandera. Si al recibir el carácter ETB,  no hubo error, el receptor  muestra
los caracteres recibidos en un display de siete segmentos.Si hubo error, se repite el proceso anterior.

Al finalizar, se envia un carácter XOFF (0x13) al transmisor para que deje de enviar datos. 
Cuando el transmisor recibe XOFF, deja de transmitir y enciende un led.




