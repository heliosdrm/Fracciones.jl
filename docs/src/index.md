# Fracciones

## Aritmética de fracciones en Julia

El paquete `Fracciones` ha sido creado con propósitos didácticos, para mostrar
algunas técnicas de programación con Julia.
Para un uso "serio" de números racionales se recomienda usar el tipo `Rational`
del módulo `Base` de Julia.

Este paquete define el tipo `Fraccion`:

```@docs
Fraccion
```

Los números de este tipo se pueden crear también a partir de la división de
otros dos números interpretables como enteros u otras fracciones, a través de
la función `fraccion`, o más convenientemente mediante la macro `@fraccion`:

```@docs
fraccion
@fraccion
```

El tipo `Fraccion` se puede emplear en operaciones aritméticas básicas
(suma, resta, multiplicación, división y potencia con números enteros).
Además, están disponibles las siguientes funciones:

```@docs
numerador
denominador
reciproco
```
