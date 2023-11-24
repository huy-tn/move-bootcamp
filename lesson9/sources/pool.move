/// A flash loan that works for any Coin type
module lesson9::flash_lender {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct FlashLender<phantom T> has key {
        id: UID,
        /// So luong coin duoc phep vay
        to_lend: Balance<T>,
        fee: u64,
    }

    /// Day la struct khong co key va store, nen no se khong duoc transfer va khong duoc luu tru ben vung. va no cung khong co drop nen cach duy nhat de xoa no lam goi ham repay.
    /// Day la cai chung ta muon cho mot goi vay.
    struct Receipt<phantom T> {
        flash_lender_id: ID,
        repay_amount: u64
    }

    /// Mot doi tuong truyen dat dac quyen rut tien va gui tien vao
    /// truong hop cua `FlashLender` co ID `flash_lender_id`. Ban dau duoc cap cho nguoi tao cua `FlashLender`
    /// va chi ton tai mot `AdminCap` duy nhat cho moi nha cho vay.
    struct AdminCap has key, store {
        id: UID,
        flash_lender_id: ID,
    }

    const EAdminOnly: u64 = 0;
    const EInvalidAmount: u64 = 1;
    const EMismatchReceipt: u64 = 2;
    const EExceededLoan: u64 = 3;
    const EExceededWithdraw: u64 = 4;

    // === Creating a flash lender ===

    /// Tao mot doi tuong `FlashLender` chia se lam cho `to_lend` co san de vay
    /// Bat ky nguoi vay nao se can tra lai so tien da vay va `fee` truoc khi ket thuc giao dich hien tai.
    public fun new<T>(to_lend: Balance<T>, fee: u64, ctx: &mut TxContext): AdminCap {
        let flash_lender = FlashLender { 
            id: object::new(ctx), 
            to_lend,
            fee
        };
        let flash_lender_id = object::id(&flash_lender);
        transfer::share_object(flash_lender);

        AdminCap { 
            id: object::new(ctx),
            flash_lender_id
        }
    }

    /// Giong nhu `new`, nhung chuyen `AdminCap` cho nguoi gui giao dich
    public entry fun create<T>(to_lend: Coin<T>, fee: u64, ctx: &mut TxContext) {
        let balance = coin::into_balance(to_lend);
        let admin_cap = new(balance, fee, ctx);

        transfer::public_transfer(admin_cap, tx_context::sender(ctx))
    }

   /// Yeu cau mot khoan vay voi `amount` tu `lender`. `Receipt<T>`
   /// dam bao rang nguoi vay se goi `repay(lender, ...)` sau nay trong giao dich nay.
   /// Huy bo neu `amount` lon hon so tien ma `lender` co san de cho vay.
    public fun loan<T>(
        self: &mut FlashLender<T>, amount: u64, ctx: &mut TxContext
    ): (Coin<T>, Receipt<T>) {
        let to_lend = &mut self.to_lend;
        assert!(balance::value(to_lend) >= amount, EExceededLoan);
        let loan = coin::take(to_lend, amount, ctx);
        let repay_amount = amount + self.fee;

        let receipt = Receipt { 
            flash_lender_id: object::id(self),
            repay_amount 
        };

        (loan, receipt)
    }

   /// Tra lai khoan vay duoc ghi lai boi `receipt` cho `lender` voi `payment`.
   /// Huy bo neu so tien tra lai khong chinh xac hoac `lender` khong phai la `FlashLender` da cap khoan vay ban dau.
    public fun repay<T>(self: &mut FlashLender<T>, payment: Coin<T>, receipt: Receipt<T>) {
        let Receipt { flash_lender_id, repay_amount } = receipt;
        assert!(object::id(self) == flash_lender_id, EMismatchReceipt);
        assert!(coin::value(&payment) == repay_amount, EInvalidAmount);

        coin::put(&mut self.to_lend, payment)
    }

    /// Cho phep quan tri vien cua `self` rut tien.
    public fun withdraw<T>(self: &mut FlashLender<T>, admin_cap: &AdminCap, amount: u64, ctx: &mut TxContext): Coin<T> {
        check_admin(self, admin_cap);

        let to_lend = &mut self.to_lend;
        assert!(balance::value(to_lend) >= amount, EExceededWithdraw);
        coin::take(to_lend, amount, ctx)
    }

    public entry fun deposit<T>(self: &mut FlashLender<T>, admin_cap: &AdminCap, coin: Coin<T>) {
        // Chi co chu so huu cua `AdminCap` cho `self` moi co the gui tien vao.
        check_admin(self, admin_cap);
        coin::put(&mut self.to_lend, coin);
    }

    /// Cho phep quan tri vien cap nhat phi cho `self`.
    public entry fun update_fee<T>(self: &mut FlashLender<T>, admin_cap: &AdminCap, new_fee: u64) {
        check_admin(self, admin_cap);
        self.fee = new_fee

    }

    fun check_admin<T>(self: &FlashLender<T>, admin_cap: &AdminCap) {
        assert!(object::borrow_id(self) == &admin_cap.flash_lender_id, EAdminOnly);
    }


    /// Return the current fee for `self`
    public fun fee<T>(self: &FlashLender<T>): u64 {
        self.fee
    }

    /// Tra ve so tien toi da co san de muon.
    public fun max_loan<T>(self: &FlashLender<T>): u64 {
        balance::value(&self.to_lend)
    }

    /// Tra ve so tien ma nguoi giu `self` phai tra lai.
    public fun repay_amount<T>(self: &Receipt<T>): u64 {
        self.repay_amount
    }

    /// Tra ve so tien ma nguoi giu `self` phai tra lai.
    public fun flash_lender_id<T>(self: &Receipt<T>): ID {
        self.flash_lender_id
    }
}
