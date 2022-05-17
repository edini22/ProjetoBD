DROP TRIGGER t_atualiza_stock ON itens;--RESOLVER ESTE TRIGGER!!!
CREATE TRIGGER t_atualiza_stock
BEFORE INSERT ON itens
FOR EACH ROW
EXECUTE PROCEDURE atualiza_stock();

CREATE OR REPLACE FUNCTION atualiza_stock()
RETURNS TRIGGER 
AS $$
DECLARE
    quant INTEGER;
BEGIN
    SELECT p.stock from produtos p where p.id = NEW.produto_id into quant;
    if quant < NEW.quantidade then
        raise exception 'Quantidade indisponivel em stock';
    ELSE
        update produtos p set p.stock = p.stock - NEW.quantidade 
        where produto_id = NEW.id;
    END IF;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;