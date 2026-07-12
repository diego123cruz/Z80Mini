          org $9000

define(link, 0)
define(head, `
      dw link
      db 0
$1:
      define(`link', `$1')
      defm len($2), "patsubst($2, ", `",34,"')"
      ifelse($3,DOCOLON,, call $3)
      ')

boot:
          head(abcd, abcd, DOCOLON)
          db $ab,$cd
          head(xyz, ', DOCOLON)
          db $69

DOCOLON:
        ret
        dw link
