/* ¿Cuáles fueron los 5 productos más vendidos (por cantidad total), 
y cuál fue el vendedor que más unidades vendió de cada uno? */

--CREO LA TABLA CON EL TOP 5 --
¿Cuáles fueron los 5 productos más vendidos (por cantidad total), 
y cuál fue el vendedor que más unidades vendió de cada uno?
VentasPorVendedorProducto AS (
    -- Calcula la cantidad vendida por cada vendedor para cada producto
    SELECT
        ProductID,
        SalesPersonID,
        SUM(Quantity) AS cantidad_vendida_por_vendedor
    FROM
        Sales
    GROUP BY
        ProductID, SalesPersonID
),
VendedorTopPorProducto AS (
    -- Identifica al vendedor con la mayor cantidad vendida para cada producto
    SELECT
        ProductID,
        SalesPersonID,
        cantidad_vendida_por_vendedor,
        ROW_NUMBER() OVER(PARTITION BY ProductID ORDER BY cantidad_vendida_por_vendedor DESC) as rn
    FROM
        VentasPorVendedorProducto
)
-- Une las CTEs para obtener el resultado final
SELECT
    pmv.ProductName, -- Mostramos el nombre del producto
    pmv.cantidad_total_vendida,
    vtpp.SalesPersonID AS vendedor_mas_unidades
FROM
    ProductosMasVendidos pmv
JOIN
    VendedorTopPorProducto vtpp
    ON pmv.ProductID = vtpp.ProductID
WHERE
    vtpp.rn = 1
ORDER BY
    pmv.cantidad_total_vendida DESC;


--Una vez obtenga los resultados, en el análisis responde: 

--¿Hay algún vendedor que aparece más de una vez como el que más vendió un producto?

--¿Algunos de estos vendedores representan más del 10% de la ventas de este producto?


--su resultado que hay un vendedor que vendio mas de una vez pero diferente prodcuto, y todos
--se encuentran por debajo del 10%
WITH ProductosMasVendidosDetalle AS (
    SELECT
        s.ProductID,
        p.ProductName,
        SUM(s.Quantity) AS cantidad_total_vendida
    FROM
        Sales s
    JOIN
        Products p ON s.ProductID = p.ProductID
    GROUP BY
        s.ProductID, p.ProductName
    ORDER BY
        cantidad_total_vendida DESC
    LIMIT 5
),
VentasPorVendedorProducto AS (
    SELECT
        ProductID,
        SalesPersonID,
        SUM(Quantity) AS cantidad_vendida_por_vendedor
    FROM
        Sales
    GROUP BY
        ProductID, SalesPersonID
),
VendedorTopPorProducto AS (
    SELECT
        ProductID,
        SalesPersonID,
        cantidad_vendida_por_vendedor,
        ROW_NUMBER() OVER(PARTITION BY ProductID ORDER BY cantidad_vendida_por_vendedor DESC) as rn
    FROM
        VentasPorVendedorProducto
)
SELECT
    pmvd.ProductName,
    pmvd.cantidad_total_vendida,
    vtpp.SalesPersonID AS vendedor_mas_unidades,
    vtpp.cantidad_vendida_por_vendedor AS cantidad_vendida_por_vendedor_top,
    (vtpp.cantidad_vendida_por_vendedor * 100.0 / pmvd.cantidad_total_vendida) AS porcentaje_venta_vendedor_top,
    CASE
        WHEN (vtpp.cantidad_vendida_por_vendedor * 100.0 / pmvd.cantidad_total_vendida) > 10 THEN 'Sí, más del 10%'
        ELSE 'No, menos del 10%'
    END AS supera_10_porciento
FROM
    ProductosMasVendidosDetalle pmvd
JOIN
    VendedorTopPorProducto vtpp
    ON pmvd.ProductID = vtpp.ProductID
WHERE
    vtpp.rn = 1
ORDER BY
    pmvd.cantidad_total_vendida DESC;


/*¿A qué categorías pertenecen los 5 productos más 
vendidos y qué proporción representan dentro del total 
de unidades vendidas de su categoría? Utiliza funciones de 
ventana para comparar la relevancia de cada producto dentro 
de su propia categoría.*/

WITH Top5Products AS (
    -- 1. Identificar los 5 productos más vendidos globalmente
    SELECT
        s.ProductID,
        p.ProductName,
        p.CategoryID,
        SUM(s.Quantity) AS total_quantity_sold_product
    FROM
        Sales s
    JOIN
        Products p ON s.ProductID = p.ProductID
    GROUP BY
        s.ProductID, p.ProductName, p.CategoryID
    ORDER BY
        total_quantity_sold_product DESC
    LIMIT 5
),
CategorySales AS (
    -- 2. Calcular la cantidad total vendida para cada categoría
    SELECT
        p.CategoryID,
        c.CategoryName,
        SUM(s.Quantity) AS total_quantity_sold_category
    FROM
        Sales s
    JOIN
        Products p ON s.ProductID = p.ProductID
    JOIN
        Categories c ON p.CategoryID = c.CategoryID
    GROUP BY
        p.CategoryID, c.CategoryName
)
-- 3. Unir los resultados y calcular la proporción
SELECT
    tp.ProductName,
    tp.total_quantity_sold_product,
    cs.CategoryName,
    cs.total_quantity_sold_category,
    (tp.total_quantity_sold_product * 100.0 / cs.total_quantity_sold_category) AS proportion_of_category_sales_percentage
FROM
    Top5Products tp
JOIN
    CategorySales cs ON tp.CategoryID = cs.CategoryID
ORDER BY
    tp.total_quantity_sold_product DESC;

/* estos son los 5 productos 
Seafood
Snails
Poultry
Beverages
Meat

la proporción en unidades es la siguiente:

2.8547733879615365
2.7732889515981842
2.167811234141561
2.6801626737815596
2.0384855905904082 */

/*¿Cuáles son los 10 productos con mayor 
cantidad de unidades vendidas en todo el catálogo 
y cuál es su posición dentro de su propia categoría? 
Utiliza funciones de ventana para identificar el ranking 
de cada producto en su categoría. Luego, analiza si 
estos productos son también los líderes dentro de sus 
categorías o si compiten estrechamente con otros productos 
de alto rendimiento. ¿Qué observas sobre la concentración 
de ventas dentro de algunas categorías?*/

WITH ProductSales AS (
    -- 1. Calcular la cantidad total vendida por cada producto
    SELECT
        s.ProductID,
        p.ProductName,
        p.CategoryID,
        SUM(s.Quantity) AS total_quantity_sold -- Aquí se define total_quantity_sold
    FROM
        Sales s
    JOIN
        Products p ON s.ProductID = p.ProductID
    GROUP BY
        s.ProductID, p.ProductName, p.CategoryID
),
RankedProducts AS (
    -- 2. Clasificar cada producto dentro de su propia categoría
    SELECT
        ps.ProductID,
        ps.ProductName,
        ps.CategoryID,
        ps.total_quantity_sold,
        RANK() OVER (PARTITION BY ps.CategoryID ORDER BY ps.total_quantity_sold DESC) AS rank_in_category,
        c.CategoryName
    FROM
        ProductSales ps
    JOIN
        Categories c ON ps.CategoryID = c.CategoryID
),
Top10GlobalProducts AS (
    -- 3. Identificar los 10 productos con mayor cantidad de unidades vendidas en todo el catálogo
    SELECT
        ProductID,
        ProductName,
        CategoryID,
        CategoryName,
        total_quantity_sold, -- Esta es la columna que debemos usar
        rank_in_category
    FROM
        RankedProducts
    ORDER BY
        total_quantity_sold DESC
    LIMIT 10
)
-- Consulta final para mostrar los 10 productos más vendidos globalmente
-- y su posición dentro de su categoría
SELECT
    tgp.ProductName,
    tgp.CategoryName,
    tgp.total_quantity_sold, -- Eliminamos el alias global_total_sold aquí
    tgp.rank_in_category
FROM
    Top10GlobalProducts tgp
ORDER BY
    tgp.total_quantity_sold DESC;