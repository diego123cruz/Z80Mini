# Algoritmo de Colisão AABB (Axis-Aligned Bounding Box) para Z80
Escrito por https://manus.im/

## Introdução

Este documento descreve um algoritmo simples e eficiente para detectar colisões entre dois retângulos alinhados aos eixos (Axis-Aligned Bounding Box - AABB) na tela de 128x64 do Z80Mini. A eficiência é crucial devido às limitações de processamento e memória do Z80.

O método AABB é ideal para o seu caso, pois você confirmou que os objetos são retangulares e a detecção por caixa delimitadora é suficiente.

## Lógica do Algoritmo

A ideia central é verificar se existe alguma separação entre os dois retângulos, seja no eixo horizontal (X) ou no eixo vertical (Y). Se houver separação em qualquer um dos eixos, os retângulos não colidem. Se não houver separação em *nenhum* dos eixos (ou seja, há sobreposição em ambos), então eles colidem.

Para dois retângulos, A e B, definidos por suas coordenadas do canto superior esquerdo (x, y) e suas dimensões (largura w, altura h):

*   **Retângulo A:** (Ax, Ay, Aw, Ah)
*   **Retângulo B:** (Bx, By, Bw, Bh)

Calculamos as coordenadas das bordas direita e inferior:

*   ARight = Ax + Aw
*   ABottom = Ay + Ah
*   BRight = Bx + Bw
*   BBottom = By + Bh

Os retângulos **NÃO** colidem se **QUALQUER** uma das seguintes condições for verdadeira:

1.  A está totalmente à esquerda de B: `ARight <= Bx`
2.  A está totalmente à direita de B: `Ax >= BRight`
3.  A está totalmente acima de B: `ABottom <= By`
4.  A está totalmente abaixo de B: `Ay >= BBottom`

Se **NENHUMA** dessas condições for verdadeira, significa que há sobreposição em ambos os eixos, e portanto, há uma colisão.

## Pseudocódigo Otimizado para Z80

Este pseudocódigo representa a lógica de forma que possa ser facilmente traduzida para Assembly Z80 ou uma linguagem de baixo nível como C, focando em operações simples.

```pseudocode
// Função: CheckCollisionAABB
// Entradas: Coordenadas e dimensões dos retângulos A e B.
//         (Ax, Ay, Aw, Ah, Bx, By, Bw, Bh)
//         Assumindo que todos são valores de 8 bits (0-255),
//         adequados para a tela 128x64.
// Saída: Retorna VERDADEIRO (ex: 1) se houver colisão,
//        FALSO (ex: 0) caso contrário.

FUNÇÃO CheckCollisionAABB(Ax, Ay, Aw, Ah, Bx, By, Bw, Bh)

    // Calcula bordas direita e inferior de A
    ARight = Ax + Aw
    ABottom = Ay + Ah

    // Calcula bordas direita e inferior de B
    BRight = Bx + Bw
    BBottom = By + Bh

    // --- Verificações de NÃO-COLISÃO --- 

    // 1. A está à esquerda de B?
    COMPARAR ARight, Bx
    SE ARight <= Bx ENTÃO
        RETORNAR FALSO // Não há colisão
    FIMSE

    // 2. A está à direita de B?
    COMPARAR Ax, BRight
    SE Ax >= BRight ENTÃO
        RETORNAR FALSO // Não há colisão
    FIMSE

    // 3. A está acima de B?
    COMPARAR ABottom, By
    SE ABottom <= By ENTÃO
        RETORNAR FALSO // Não há colisão
    FIMSE

    // 4. A está abaixo de B?
    COMPARAR Ay, BBottom
    SE Ay >= BBottom ENTÃO
        RETORNAR FALSO // Não há colisão
    FIMSE

    // --- Colisão Detectada --- 
    // Se chegou até aqui, nenhuma condição de não-colisão foi atendida.
    RETORNAR VERDADEIRO // Há colisão

FIM FUNÇÃO
```

## Considerações para Implementação em Z80

*   **Tipos de Dados:** Use bytes (8 bits) para coordenadas e dimensões, pois a tela é 128x64.
*   **Registradores:** Carregue os valores de Ax, Ay, Aw, Ah, Bx, By, Bw, Bh em registradores (como A, B, C, D, E, H, L) para acesso rápido.
*   **Cálculos:** As somas (`Ax + Aw`, etc.) podem ser feitas com a instrução `ADD` do Z80. Como os resultados podem teoricamente exceder 127 (mas não 255 no contexto da tela), use aritmética de 8 bits sem sinal.
*   **Comparações:** Use a instrução `CP` para comparações. Ela ajusta as flags (Zero, Carry, Sign) que podem ser usadas com instruções de salto condicional (`JP cc`, `JR cc`).
*   **Retorno:** Use uma convenção para o valor de retorno. Por exemplo, retornar 0 no registrador A para FALSO e 1 (ou qualquer valor não-zero) para VERDADEIRO, ou usar o estado da flag Carry.
*   **Eficiência:** A estrutura do pseudocódigo permite sair da função assim que uma condição de não-colisão é encontrada, economizando ciclos de processamento.

Este algoritmo é um dos métodos mais rápidos para detecção de colisão entre retângulos e deve funcionar bem no seu Z80Mini.

