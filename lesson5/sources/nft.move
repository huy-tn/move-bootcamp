module lesson5::discount_coupon {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self,TxContext};
    use sui::coin;
    use sui::sui::SUI;

    struct DiscountCoupon has key {
        id: UID,
        owner: address,
        discount: u8,
        expiration: u64,
    }

    /// Lay thong tin cua nguoi so huu
    public fun owner(coupon: &DiscountCoupon): address {
        coupon.owner
    }

    /// Lay thong tin discount cua coupon
    public fun discount(coupon: &DiscountCoupon): u8 {
        coupon.discount
    }

    // Hoan thien function de mint 1 coupon va transfer coupon nay cho mot nguoi nhan recipient
    public entry fun mint_and_topup(
        coin: coin::Coin<SUI>,
        discount: u8,
        expiration: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let coupon = DiscountCoupon {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            discount,
            expiration
        };
        transfer::transfer(coupon, recipient);
        // just to avoid error but what coin is used for
        transfer::public_transfer(coin, recipient);
    }

    // hoan thien function de co the transfer coupon cho 1 nguoi khac
    public entry fun transfer_coupon(coupon: DiscountCoupon, recipient: address) {
        transfer::transfer(coupon, recipient);
    }

    // Hoan thien function de huy, xoa di coupon.
    public fun burn(nft: DiscountCoupon): bool {
        let DiscountCoupon { id, owner: _, discount: _, expiration: _ } = nft;
        object::delete(id);
        true
    }

    // Hoan thien function de nguoi dung su dung, sau do se xoa di cai coupon
    public entry fun scan(nft: DiscountCoupon) {
        // ....check information
        burn(nft);
    }
}
