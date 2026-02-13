import SwiftUI

struct SignInView: View {
    let onSignedIn: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("30-Day Discipline Arc")
                .font(.largeTitle.weight(.bold))

            Text("Sign in to begin.")
                .opacity(0.8)

            Button {
                // TODO: add Sign in with Apple
                onSignedIn()
            } label: {
                Text("Sign in with Apple")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(16)
            }
        }
        .padding()
        .preferredColorScheme(.dark)
            .padding(.horizontal, ArcSpacing.screenPadding)}
}
