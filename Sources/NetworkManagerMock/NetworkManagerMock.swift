

import Foundation
import NetworkManager
import LoggerManager

public func createAPIClientServiceMock() -> IAPIClientService {
    return APIClientService(
        logger: NoLogger(label: ""),
        configuration: .init(
            baseURL: URL(string: "https://api.themoviedb.org"),
            baseHeaders: [
                "accept": "application/json",
                "content-type": "application/json"
            ]
        )
    )
}
