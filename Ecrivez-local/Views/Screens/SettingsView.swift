import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
    )var categories: FetchedResults<Category>
    
    var body: some View {
        List {
            NavigationLink(destination: CategoryEditorListView(categories: categories)) {
                Text("Edit Categories")
            }
        }
        .navigationTitle("Settings")
    }
}
//
//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//        return SettingsView().environment(\.managedObjectContext, context)
//    }
//}
