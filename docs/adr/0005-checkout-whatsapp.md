# ADR-0005 — Checkout finalizado no WhatsApp com pedido registrado

- **Status:** Aceito
- **Data:** 2026-10-02

## Contexto

A venda **não** é paga no site. O cliente monta o carrinho e a negociação/pagamento
acontece no WhatsApp da Ana. Ao mesmo tempo, a Ana precisa de **relatório de vendas** e
**baixa de estoque** — portanto o pedido não pode existir só como texto no WhatsApp.

## Decisão

1. Ao clicar em **"Finalizar no WhatsApp"**, o app chama a RPC **`create_order`**, que:
   - valida variantes e estoque disponível;
   - **recalcula preços no servidor** (nunca confia no preço do cliente);
   - grava `orders` + `order_items` com status **`pending`** e a **origem** (ADR-0007);
   - retorna um **código curto** (`K7P2QX`, 6 caracteres, alfabeto sem ambíguos `0/O/1/I`).
2. O app monta a mensagem (`WhatsAppMessageBuilder`) e abre
   `https://wa.me/<numero>?text=<mensagem-url-encoded>` na **mesma aba**.
3. A mensagem leva o **link do pedido** `https://<dominio>/pedido/K7P2QX` — é por ele que a
   Ana confirma a venda e dá baixa no estoque (ADR-0006).

### Formato da mensagem

```text
Olá, Ana! 👋 Quero fazer este pedido:

🧾 Pedido #K7P2QX

1) Vestido Midi Linho
   Tam: M | Cor: Rosa | Qtd: 1 | R$ 189,90
2) Camisa Oxford
   Tam: G | Cor: Azul | Qtd: 2 | R$ 259,80

💰 Total: R$ 449,70
👤 Nome: Maria
📝 Obs: posso retirar sábado?

🔗 Ver pedido: https://ondasquefaltam.com.br/pedido/K7P2QX
```

- Número da Ana vem de `store_settings.whatsapp_number` (editável no admin) — não fica no código.
- Limite prático de URL: manter a mensagem enxuta; o link do pedido é a fonte da verdade.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Só mensagem de texto, sem gravar pedido | Sem relatório, sem baixa de estoque, sem métrica de origem. |
| Gravar pedido via `insert` direto do cliente | Cliente poderia forjar preço/quantidade; RLS sozinho não valida regra. |
| WhatsApp Business API (Cloud API) | Custo e burocracia (Meta), desnecessário para o volume. |
| Gateway de pagamento | Fora do escopo; a Ana quer negociar no WhatsApp. |

## Consequências

- **+** Todo pedido iniciado fica registrado, mesmo que não vire venda → mede **conversão**.
- **−** Pedidos `pending` "abandonados" se acumulam. Mitigação (fase 2): status `expired`
  automático após N dias via `pg_cron`, e filtro no admin.
- **−** Spam de pedidos anônimos é possível. Mitigação: limite de itens/quantidade por pedido na
  RPC e rate limit simples por `session_id` (ex.: máx. 5 pedidos/hora).
