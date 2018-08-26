/**
 Persistence methods related to sponsors.
 */
extension Persistence {
    
    /**
     Adds a sponsor.
     
     To implement the weight of a sponsor, multiple copies are added to the collection.
     This way, picking a random sponsor is as easy as picking a random document from the collection.
     
     - Throws: ServerError.conflict if a sponsor with this code already exists.
     */
    func add(_ sponsor: Sponsor) throws {
        guard try sponsors.findOne(["code": sponsor.code]) == nil else {
            throw log(ServerError.conflict)
        }
        guard sponsor.weight >= 1 else {
            throw log(ServerError.invalidState)
        }
        for _ in 1...sponsor.weight {
            try sponsors.insert(sponsor.document)
        }
    }
    
    /**
     Removes a sponsor.
     */
    func remove(_ sponsor: Sponsor) throws {
        try sponsors.remove(["code": sponsor.code])
    }
    
    /**
     Updates a sponsor's information.
     */
    func update(_ sponsor: Sponsor) throws {
        try remove(sponsor)
        try add(sponsor)
    }
    
    /**
     Returns the sponsor with the given code.
     */
    func sponsor(withCode code: String) throws -> Sponsor? {
        guard var document = try sponsors.findOne(["code": code]) else {
            return nil
        }
        document["weight"] = try sponsors.count(["code": code])
        return try Sponsor(document)
    }
    
    /**
     Returns a random sponsor, taking the weight of the sponsors into account.
     
     A sponsor with weight s has a s/t percent change of being returned,
     where t is the total combined weight of all sponsors.
     */
    func randomSponsor() throws -> Sponsor? {
        guard var result = try sponsors.aggregate([.sample(sizeOf: 1)]).next() else {
            return nil
        }
        result["weight"] = try sponsors.count(["code": result["code"]])
        return try Sponsor(result)
    }
    
    /**
     Returns all sponsors, sorted by weight descending.
     */
    func allSponsors() throws -> [Sponsor] {
        guard let codes = try sponsors.distinct(on: "code") else {
            return []
        }
        return try codes.compactMap {
            var document = try sponsors.findOne(["code": $0])!
            document["weight"] = try sponsors.count(["code": document["code"]])
            return try Sponsor(document)
        }.sorted { $0.weight > $1.weight }
    }
}
