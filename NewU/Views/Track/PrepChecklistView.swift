import SwiftUI

struct PrepChecklistView: View {
    let isCompound: Bool
    let onDismiss: () -> Void
    let onComplete: () -> Void

    @State private var checkedItems: Set<Int> = []

    private var steps: [(Int, String)] {
        var items: [(Int, String)] = [
            (0, "Wash hands"),
            (1, "Gather supplies (pen/syringe, alcohol swabs)"),
            (2, "Check medication expiration date"),
        ]
        if isCompound {
            items.append((3, "Reconstitute peptide (see Calculator tab)"))
        }
        items += [
            (4, "Clean injection site with alcohol swab"),
            (5, "Let alcohol dry"),
            (6, "Inject medication"),
            (7, "Apply gentle pressure"),
            (8, "Dispose of needle safely"),
        ]
        return items
    }

    private var allChecked: Bool {
        steps.allSatisfy { checkedItems.contains($0.0) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(steps, id: \.0) { index, text in
                        Button {
                            withAnimation {
                                if checkedItems.contains(index) {
                                    checkedItems.remove(index)
                                } else {
                                    checkedItems.insert(index)
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: checkedItems.contains(index) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(checkedItems.contains(index) ? .green : .secondary)
                                    .font(.title3)

                                Text(text)
                                    .strikethrough(checkedItems.contains(index))
                                    .foregroundStyle(checkedItems.contains(index) ? .secondary : .primary)
                            }
                        }
                    }
                } header: {
                    Text("Shot Day Prep")
                } footer: {
                    Text("Complete each step before injecting for safety.")
                }
            }
            .navigationTitle("Prep Checklist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onComplete() }
                        .disabled(!allChecked)
                }
            }
        }
    }
}
