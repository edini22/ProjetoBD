-- Users ============================================================================

--Admins
SELECT ADD_ADMIN('edini', 'password01', 'Eduardo Figueiredo');
SELECT ADD_ADMIN('fabirino', 'password02', 'Fábio Santos');


-- Compradores
SELECT ADD_COMPRADOR('josem', 'password03', 'José Maria','Rua da Catraia, Lisboa');
SELECT ADD_COMPRADOR('anamargarida', 'password04', 'Ana Margarida','Avenida das Laranjeiras, Anadia');

-- Vendedores
SELECT ADD_VENDEDOR('infortech', 'password05', 'InforTech LDA',521376896);
SELECT ADD_VENDEDOR('techmania', 'password06', 'TechMania',624786152);


-- Produtos =========================================================================

-- -- Computadores
SELECT add_computador(max_id() +1,1,'Computador1', 'Intel i7 16GB RTX 3060', 1300, 3,5,'Intel i7 12700k', 16, 1024, 'RTX 3060');
SELECT add_computador(max_id() +1,1,'Computador1', 'Intel i7 16GB RTX 3060', 1300, 3,6,'Intel i7 12700k', 16, 1024, 'RTX 3060');
SELECT add_computador(max_id() +1,1,'Computador2', 'Ryzen9 5900x 32GB RTX 3090', 4000, 1,6,'Ryzen9 5900x', 32, 1024, 'RTX 3090');

-- Telemoveis

SELECT add_telemovel(max_id() +1,1, 'ePhone5', 'O melhor telemovel de sempre', 600, 5, 5, 5.2, 6, 128);
SELECT add_telemovel(max_id() +1,1, 'ecoPhone3', 'Melhor custo benificio', 200, 2, 6, 6, 4, 64);
SELECT add_telemovel(max_id() +1,1, 'Space4', 'Rapido como a luz', 999, 3, 5, 6.1, 8, 256);


-- Televisoes

SELECT add_televisao(max_id() +1,1, 'MyTV', 'Resolucao que nunca mais acaba', 1300, 4, 5, 60, 7680);
SELECT add_televisao(max_id() +1,1, 'CimenaTV', 'Como se estivesse no cinema', 700, 2, 6, 43, 3840);
SELECT add_televisao(max_id() +1,1, 'TVex', 'A melhor televisao de sempre', 500, 7, 5, 43, 3840);