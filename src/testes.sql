SELECT * FROM utilizadores;
SELECT * FROM compradores;
SELECT * FROM vendedores;
SELECT * FROM admins;

SELECT * FROM produtos;
SELECT * FROM televisoes;

SELECT * from comentario;

SELECT * from compras;

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