log using "C:\Users\Usuario\OneDrive\Escritorio\3ro GANE\Mdo Trabajo\Informatica\Tercer Video\resultado.smcl"

//Introducimos datos:
cd "C:\Users\usuario\OneDrive\Escritorio\3ro GANE\Mdo Trabajo\Informatica\Tercer Video"
use "datos-video4.dta", clear

*FASE 1: lectura datos, construcción variables, estadísitcas descriptivas y planteamiento modelo
**1. Individuos y años de la muestra:
describe
levelsof nace2
levelsof pais
levelsof year

***Seleccioamos variables de uso:
global y EMP
global x VA_CP COMP_EMPE p_K GO_CP_TOT
 

**2. ¿Base de datos balanceada o no balanceada?
***Creamos variable individuo que represente cada sector y cada país
egen id=group(nace2 pais)
xtset id year
xtdescribe

**3. Imponemos estructura balanceada:
by id: gen nyear=[_N]
keep if nyear==11

**4. Analizamos variabilidad de los datos:
xtsum $y $x

*FASE 2: estimación elasticidad sustitución trabajo-capital
**1. Modelo econométrico y análisis de los coeficientes

**2.  Métodos de estimación: 
***Concretamos variables de uso:
gen lE=log(EMP)
global ly lE
global lx lVA_CP lCOMP_EMPE lp_K lGO_CP_TOT
replace $y=. if $y==0
foreach var of global x {
qui replace `var'=. if `var'==0
qui gen l`var'=log(`var')
}
order id nace2 year pais //Para establecer estas variables al principio
sort id year //Organizamos muestra

***a) Labour demand pooled (ldp)
reg $ly $lx, vce(cluster id) //Indicamos tenemos diferentes individuos (estimadores robustos, minimizamos ES)
estimates store ldp0

***b) Labour demand random efects (ldre)
xtreg $ly $lx, re //se calcula como media ponderada de las estimadores within y between
estimates store ldre0

***c) Labour demand fixed effects (ldfe)
xtreg $ly $lx, fe
estimates store ldfe0

***d) Labour demand least square dummy variable (ldlsdv)
areg $ly $lx, absorb(id) //Evitamos introducir manualmente variable por individuos
estimates store ldlsdv0

**3. Comparamos modelos
estimates table ldp0 ldre0 ldfe0 ldlsdv0, stats (r2_a r2_o r2_w r2_b rho corr)
hausman ldre0 ldfe0

**4. Conclusiones modelo
xtreg $ly $lx, fe

**5. Creamos variables necesarias
***a) Ratio capital/empleo y salario/coste del capital
gen ratioEK=EMP/K_GFCF
gen lratioEK=log(ratioEK)
replace lratioEK=0 if lratioEK==.

gen ratiorw=p_K/COMP_EMPE
gen lratiorw=log(ratiorw)
replace lratiorw=0 if lratiorw==.

***b) Creamos globales y estimamos modelo inicial
global ly2 lratioEK
global lx2 lVA_CP lGO_CP_TOT

xtreg $ly2 $lx2 lratiorw, fe
estimates store se1_fe
 
***c) Creamos variable categorica por grupo de países
gen gp=.
replace gp=1 if pais==4 | pais==9 | pais==10 | pais==16 | pais==21 | pais==24 
replace gp=2 if pais==7 | pais==8 | pais==11 | pais==18 | pais==20 | pais==26 
replace gp=3 if pais==1 | pais==5 | pais==6 | pais==13 | pais==14 | pais==19 |  pais==22 | pais==23 | pais==27 | pais==28 
replace gp=4 if pais==3 | pais==25
replace gp=5 if pais==2 | pais==12 | pais==15 | pais==29
replace gp=. if pais==17 //eliminamos japón pues distinta forma funcionamiento y medidad del mercado 

label define pais 1 "Sur" 2 "Norte" 3 "Centro" 4 "Este" 5 "Oeste"
label values gp pais

***d) Estimamos modelo
xtreg $ly2 $lx2 i.gp#c.lratiorw i.gp, re // re para evitar problema de multicolinealidad
estimates store se2_re

***e) Cuadro resumen y análisis coeficientes
estimates table se1_fe se2_re, stats(r2_o r2_b r2_w corr)

coefplot se2_re, keep(*gp#c.lratiorw) gen (result)

save resultplot, replace

log close








