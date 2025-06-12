/*Crea un trigger que registre en una tabla de monitoreo 
cada vez que un producto supere las 200.000 unidades 
vendidas acumuladas.

El trigger debe activarse después de insertar una nueva venta 
y registrar en la tabla el ID del producto, su nombre, 
la nueva cantidad total de unidades vendidas, y la fecha 
en que se superó el umbral.*/


--CREAMOS LA TABLA--
CREATE TABLE ProductSalesThresholdMonitor (
    monitor_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    total_units_sold_at_threshold INT NOT NULL,
    threshold_exceeded_date DATETIME NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--CREAMOS EL TRIGGER--
CREATE TRIGGER trg_ProductSalesThreshold
AFTER INSERT ON Sales
FOR EACH ROW
BEGIN
    INSERT INTO ProductSalesThresholdMonitor (
        product_id,
        product_name,
        total_units_sold_at_threshold,
        threshold_exceeded_date
    )
    SELECT
        NEW.ProductID,
        (SELECT ProductName FROM Products WHERE ProductID = NEW.ProductID),
        SUM(s.Quantity),
        NEW.SalesDate
    FROM
        Sales s
    WHERE
        s.ProductID = NEW.ProductID
    GROUP BY
        s.ProductID
    HAVING
        SUM(s.Quantity) > 200000
        AND NOT EXISTS (SELECT 1 FROM ProductSalesThresholdMonitor WHERE product_id = NEW.ProductID);
END;


/*Registra una venta correspondiente al vendedor con ID 9, 
al cliente con ID 84, del producto con ID 103, 
por una cantidad de 1.876 unidades y un valor de 1200 unidades.

Consulta la tabla de monitoreo, toma captura de los resultados 
y realiza un análisis breve de lo ocurrido.*/


--PRIMERO REGISTRAMOS LA VENTA--
INSERT INTO Sales (SalesID, SalesPersonID, CustomerID, ProductID, Quantity, Discount, TotalPrice, SalesDate)
VALUES (1000, 9, 84, 103, 1876, 0.00, 1200.00, '2025-06-10 23:38:35');
--CONSULTA MONITOREO--
SELECT * FROM ProductSalesThresholdMonitor;


/*Selecciona dos consultas del avance 1 y crea los índices que 
consideres más adecuados para optimizar su ejecución.

Prueba con índices individuales y compuestos, 
según la lógica de cada consulta. Luego, vuelve a ejecutar 
y compara los tiempos de ejecución antes y después 
de aplicar los índices. Finalmente, describe brevemente 
el impacto que tuvieron los índices en el rendimiento y 
en qué tipo de columnas resultan más efectivos para este 
tipo de operaciones.*/

-- Índices para la tabla Sales
CREATE INDEX idx_sales_productid_quantity ON Sales (ProductID, Quantity);
CREATE INDEX idx_sales_salespersonid_productid_quantity ON Sales (SalesPersonID, ProductID, Quantity);

-- Índices para la tabla Products
CREATE INDEX idx_products_productid_categoryid ON Products (ProductID, CategoryID);