import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject var cartService: CartService // Değişiklik: ViewModel yerine CartService kullanılıyor
    @Environment(\.dismiss) private var dismiss
    
    @State private var deliveryAddress = ""
    @State private var phoneNumber = ""
    @State private var notes = ""
    @State private var selectedPaymentMethod: PaymentMethod = .CASH
    
    @State private var showingAddressValidation = false
    @State private var showingPhoneValidation = false
    
    var isFormValid: Bool {
        !deliveryAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        deliveryAddress.count >= 10 &&
        !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        phoneNumber.count >= 10
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Order Summary
                    if let cart = cartService.cart {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Sipariş Özeti")
                                .font(.system(size: 20, weight: .semibold))
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Toplam Ürün:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(cart.totalItems) adet")
                                        .fontWeight(.medium)
                                }
                                
                                HStack {
                                    Text("Toplam Tutar:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(cartService.formatPrice(cart.totalAmount))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                    
                    // Delivery Address
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Teslimat Adresi")
                            .font(.system(size: 18, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Tam adresinizi girin", text: $deliveryAddress, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                                .onSubmit {
                                    validateAddress()
                                }
                                .onChange(of: deliveryAddress) { _, _ in
                                    showingAddressValidation = false
                                }
                            
                            if showingAddressValidation {
                                Text("Lütfen geçerli bir teslimat adresi girin (en az 10 karakter)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            } else {
                                Text("Örn: Kızılay Mahallesi, Atatürk Bulvarı No:123, Çankaya/Ankara")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Phone Number
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Telefon Numarası")
                            .font(.system(size: 18, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("0555 123 45 67", text: $phoneNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                                .onSubmit {
                                    validatePhoneNumber()
                                }
                                .onChange(of: phoneNumber) { _, _ in
                                    showingPhoneValidation = false
                                }
                            
                            if showingPhoneValidation {
                                Text("Lütfen geçerli bir telefon numarası girin")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            } else {
                                Text("Teslimat sırasında sizinle iletişim kurmak için kullanılacak")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Payment Method
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ödeme Yöntemi")
                            .font(.system(size: 18, weight: .semibold))
                        
                        VStack(spacing: 8) {
                            ForEach(PaymentMethod.allCases, id: \.self) { method in
                                Button(action: {
                                    selectedPaymentMethod = method
                                }) {
                                    HStack {
                                        Image(systemName: selectedPaymentMethod == method ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedPaymentMethod == method ? .blue : .gray)
                                        
                                        Text(method.displayName)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if method == .CASH {
                                            Text("Kapıda Ödeme")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedPaymentMethod == method ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Özel Notlar (İsteğe Bağlı)")
                            .font(.system(size: 18, weight: .semibold))
                        
                        TextField("Kurye için özel talimatlarınız varsa yazın", text: $notes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(2...4)
                        
                        Text("Örn: 3. kat, kapı zili çalışmıyor, kargosuz apartman")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(20)
            }
            .navigationTitle("Sipariş Bilgileri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sipariş Ver") {
                        if validateForm() {
                            Task {
                                let success = await cartService.createOrderFromCart(
                                    deliveryAddress: deliveryAddress.trimmingCharacters(in: .whitespacesAndNewlines),
                                    phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
                                    paymentMethod: selectedPaymentMethod
                                )
                                
                                if success {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .disabled(!isFormValid || cartService.isPlacingOrder)
                    .fontWeight(.semibold)
                }
            }
            .overlay(
                Group {
                    if cartService.isPlacingOrder {
                        ZStack {
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()
                            
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Siparişiniz oluşturuluyor...")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.8))
                            )
                        }
                    }
                }
            )
        }
    }
    
    private func validateForm() -> Bool {
        var isValid = true
        
        if !validateAddress() {
            isValid = false
        }
        
        if !validatePhoneNumber() {
            isValid = false
        }
        
        return isValid
    }
    
    @discardableResult
    private func validateAddress() -> Bool {
        let trimmedAddress = deliveryAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedAddress.isEmpty || trimmedAddress.count < 10 {
            showingAddressValidation = true
            return false
        }
        showingAddressValidation = false
        return true
    }
    
    @discardableResult
    private func validatePhoneNumber() -> Bool {
        let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPhone.isEmpty || trimmedPhone.count < 10 {
            showingPhoneValidation = true
            return false
        }
        showingPhoneValidation = false
        return true
    }
}

#Preview {
    // Preview'ın çalışması için environmentObject ekliyoruz
    CheckoutView()
        .environmentObject(CartService())
}
