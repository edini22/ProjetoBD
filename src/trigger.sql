
CREATE OR REPLACE FUNCTION atualiza_stock()
RETURNS TRIGGER 
AS $$
DECLARE
    quant INTEGER;
BEGIN
    SELECT stock into quant from produtos where id = NEW.produto_id and versao = NEW.versao_produto;
    if quant < NEW.quantidade then
        raise exception 'Quantidade indisponivel em stock';
    ELSE
        update produtos set stock = stock - NEW.quantidade 
        where id = NEW.produto_id and versao = NEW.versao_produto;
    END IF;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS t_atualiza_stock ON itens;--TODO: RESOLVER ESTE TRIGGER!!!
CREATE TRIGGER t_atualiza_stock
BEFORE INSERT ON itens
FOR EACH ROW
EXECUTE PROCEDURE atualiza_stock();