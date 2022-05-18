
DROP TRIGGER IF EXISTS t_atualiza_stock ON itens;--TODO: RESOLVER ESTE TRIGGER!!!
CREATE TRIGGER t_atualiza_stock
BEFORE INSERT ON itens
FOR EACH ROW
EXECUTE PROCEDURE atualiza_stock();

DROP TRIGGER IF EXISTS t_notificacao_vendedor ON itens;
CREATE TRIGGER t_notificacao_vendedor 
AFTER INSERT ON itens
FOR EACH ROW
EXECUTE PROCEDURE notificacao_vendedor();

DROP TRIGGER IF EXISTS t_notificacao_comprador ON compras;
CREATE TRIGGER t_notificacao_comprador 
AFTER UPDATE ON compras
FOR EACH ROW
EXECUTE PROCEDURE notificacao_comprador();
