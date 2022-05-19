CREATE TRIGGER t_atualiza_stock
BEFORE INSERT ON itens
FOR EACH ROW
EXECUTE PROCEDURE atualiza_stock();

CREATE TRIGGER t_notificacao_vendedor 
AFTER INSERT ON itens
FOR EACH ROW
EXECUTE PROCEDURE notificacao_vendedor();

CREATE TRIGGER t_notificacao_comprador 
AFTER UPDATE ON compras
FOR EACH ROW
EXECUTE PROCEDURE notificacao_comprador();

CREATE TRIGGER t_notificacao_vendedor_rating 
AFTER INSERT ON ratings
FOR EACH ROW
EXECUTE PROCEDURE notificacao_vendedor_rating();

CREATE TRIGGER t_notificacao_comentario 
AFTER INSERT ON comentarios
FOR EACH ROW
EXECUTE PROCEDURE notificacao_comentario();
