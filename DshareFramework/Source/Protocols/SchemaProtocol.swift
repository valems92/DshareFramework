public protocol SchemaProtocol {
    var id:String { get }
    var userId:String { get }
    
    init(fromJson: [String: Any])
    
    func toJson() -> [String: Any]
}
