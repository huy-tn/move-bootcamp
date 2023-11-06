// Hoan thien doan code de co the publish duoc
module lesson5::FT_TOKEN {    
    use std::string::{Self, String};
    use std::ascii;
    use std::option::{Self, Option};

    use sui::coin::{Self, Coin, CoinMetadata, TreasuryCap};
    use sui::url;
    use sui::transfer;
    use sui::event;
    use sui::tx_context::{Self, TxContext};

    struct FT_TOKEN has drop { }

    fun init(witness: FT_TOKEN, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<FT_TOKEN>(
            witness,
            2,
            b"$FT_TOKEN",
            b"FT_TOKEN",
            b"Fungible Token",
            option::some(url::new_unsafe_from_bytes(b"facebook.com")),
            ctx
        );
        transfer::public_transfer(metadata, tx_context::sender(ctx));
        transfer::public_share_object(treasury_cap);

    }

    // hoan thien function de co the tao ra 10_000 token cho moi lan mint, va moi owner cua token moi co quyen mint
    public entry fun mint(_: &CoinMetadata<FT_TOKEN>, treasury_cap: &mut TreasuryCap<FT_TOKEN>, recipient: address, ctx: &mut TxContext) {
        coin::mint_and_transfer(treasury_cap, 10_000, recipient, ctx);
    }

    // Hoan thien function sau de user hoac ai cung co quyen tu dot di so token dang so huu
    public entry fun burn_token(treasury_cap: &mut TreasuryCap<FT_TOKEN>, coin: Coin<FT_TOKEN>) {
        coin::burn(treasury_cap, coin);
    }

    // Hoan thien function de chuyen token tu nguoi nay sang nguoi khac.
    public entry fun transfer_token(coin: &mut Coin<FT_TOKEN>, amount: u64, recipient: address, ctx: &mut TxContext) {
        let object_split = split_token(coin, amount, ctx);
        transfer::public_transfer(object_split, recipient);
        // sau do khoi 1 Event, dung de tao 1 su kien khi function transfer duoc thuc thi

        event::emit(TransferEvent {
            sender: tx_context::sender(ctx),
            recipient,
            amount
        })
    }

    struct TransferEvent has copy, drop {
        sender: address,
        recipient: address,
        amount: u64
    }
    // Hoan thien function de chia Token Object thanh mot object khac dung cho viec transfer
    // goi y su dung coin:: framework
    public fun split_token(token: &mut Coin<FT_TOKEN>, split_amount: u64, ctx: &mut TxContext): Coin<FT_TOKEN> {
        coin::split(token, split_amount, ctx)
    }

    // Viet them function de token co the update thong tin sau
    public entry fun update_name(metadata: &mut CoinMetadata<FT_TOKEN>, treasury_cap: &mut TreasuryCap<FT_TOKEN>, new_name: string::String) {
        coin::update_name<FT_TOKEN>(treasury_cap, metadata, new_name);
        event::emit(UpdateEvent {
            success: true,
            data: new_name,
        });
    }
    public entry fun update_description(metadata: &mut CoinMetadata<FT_TOKEN>, treasury_cap: &mut TreasuryCap<FT_TOKEN>, new_description: string::String) {
        coin::update_description<FT_TOKEN>(treasury_cap, metadata, new_description);
        event::emit(UpdateEvent {
            success: true,
            data: new_description,
        });
    }
    public entry fun update_symbol(metadata: &mut CoinMetadata<FT_TOKEN>, treasury_cap: &mut TreasuryCap<FT_TOKEN>, new_symbol: ascii::String) {
        coin::update_symbol<FT_TOKEN>(treasury_cap, metadata, new_symbol);
        event::emit(UpdateEvent {
            success: true,
            data: string::utf8(ascii::into_bytes(new_symbol)),
        });
    }      

    public entry fun update_icon_url(metadata: &mut CoinMetadata<FT_TOKEN>, treasury_cap: &mut TreasuryCap<FT_TOKEN>, new_icon_url: ascii::String) {
        coin::update_icon_url<FT_TOKEN>(treasury_cap, metadata, new_icon_url);
        event::emit(UpdateEvent {
            success: true,
            data: string::utf8(ascii::into_bytes(new_icon_url)),
        });
    }


    // su dung struct nay de tao event cho cac function update ben tren.
    struct UpdateEvent has copy, drop {
        success: bool,
        data: String
    }

    // Viet cac function de get du lieu tu token ve de hien thi
    public entry fun get_token_name(metadata: &CoinMetadata<FT_TOKEN>): String {
        coin::get_name(metadata)
    }
    public entry fun get_token_description(metadata: &CoinMetadata<FT_TOKEN>): String {
        coin::get_description(metadata)
    }
    public entry fun get_token_icon_url(metadata: &CoinMetadata<FT_TOKEN>): Option<url::Url> {
        coin::get_icon_url(metadata)
    }
    public entry fun get_token_symbol(metadata: &CoinMetadata<FT_TOKEN>): ascii::String {
        coin::get_symbol(metadata)
    }
}
