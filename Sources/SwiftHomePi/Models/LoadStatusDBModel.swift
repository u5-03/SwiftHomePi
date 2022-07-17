import Fluent
import Vapor

public enum LoadStatusModelFields: FieldKey {
    case isRemoved
}

public final class LoadStatusDBModel: Model, Content {
    public static let schema = "LoadStatus"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: LoadStatusModelFields.isRemoved.rawValue)
    public var isRemoved: Bool

    public init() { }

    public init(isRemoved: Bool) {
        id = UUID()
        self.isRemoved = isRemoved
    }
}
