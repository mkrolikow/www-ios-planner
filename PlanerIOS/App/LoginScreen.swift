import SwiftUI

struct LoginScreen: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = "admin@planer.local"
    @State private var password = "Admin123!"

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text("Planer").font(.largeTitle).bold()

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(.roundedBorder)

                SecureField("Hasło", text: $password)
                    .textFieldStyle(.roundedBorder)

                if let e = auth.error {
                    Text(e).foregroundStyle(.red).font(.footnote)
                }

                Button("Zaloguj") {
                    Task { await auth.login(email: email, password: password) }
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
        }
    }
}
