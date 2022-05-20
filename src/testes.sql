SELECT * FROM utilizadores;
SELECT * FROM compradores;
SELECT * FROM vendedores;
SELECT * FROM admins;

SELECT * FROM produtos;
SELECT * FROM televisoes;

SELECT * from comentarios;

SELECT * from compras;

SELECT GET_report_year();

SELECT EXTRACT(MONTH FROM CURRENT_DATE);

INSERT INTO compras (compra_valor, compra_data, comprador_id) VALUES (3000, '2020-02-05', 4);

SELECT COUNT(compra_id) "count", SUM(compra_valor) "sum", EXTRACT(MONTH from compra_data) "mes"
        FROM compras WHERE AGE(CURRENT_DATE, '2022-03-22') < '12 months' GROUP BY "mes";

SELECT add_compra('[
            {
                "product_id": 1,
                "quantidade" : 1
    
            },{
                "product_id": 2,
                "quantidade" : 1
            }
        ]
    ',3);

SELECT * FROM notificacoes;
SELECT notificacao_vista(3);

SELECT * FROM itens;

SELECT produto_id ,produto_versao  FROM ratings where produto_id = 1;

SELECT MAX(i.versao_produto)  FROM itens i ,compras c WHERE i.compra_id = c.compra_id and i.produto_id = 1 and c.comprador_id = 3;

SELECT comentario_pai_id  FROM comentarios WHERE id = 1;

SELECT utilizador_id FROM comentarios WHERE id = 6;

SELECT p.id  FROM produtos p WHERE p.id = 1 ORDER BY p.versao DESC;

 SELECT row_to_json(produtos)  FROM(SELECT data,preco FROM produtos WHERE id = 8) produtos ;

 SELECT GET_PRODUCT(1);