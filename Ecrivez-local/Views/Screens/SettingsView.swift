import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        List {
            NavigationLink(destination: CategoryEditorListView()) {
                Text("Edit Categories")
            }
            
            
            NavigationLink(destination: CategoryEditorListView()) {
                Text("Account Settings")
            }

            
            NavigationLink(destination: CategoryEditorListView()) {
                Text("Suggest a Feature")
            }
            
            NavigationLink(destination: CategoryEditorListView()) {
                Text("Support the developer ")
                Image(systemName: "dollarsign.arrow.circlepath")
                    .font(.system(size: 24))
            }
            .foregroundColor(.yellow)

            

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
