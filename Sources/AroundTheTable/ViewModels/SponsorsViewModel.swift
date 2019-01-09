/**
 View model for **sponsors.stencil**.
 */
struct SponsorsViewModel: Codable {
    
    let base: BaseViewModel
    
    struct SponsorViewModel: Codable {
        
        let name: String
        let description: String
        let picture: String
        let link: String
        
        init(_ sponsor: Sponsor) {
            self.name = sponsor.name
            self.description = sponsor.description
            self.picture = sponsor.picture.absoluteString
            self.link = sponsor.link.absoluteString
        }
    }
    
    let sponsors: [SponsorViewModel]
    
    init(base: BaseViewModel, sponsors: [Sponsor]) {
        self.base = base
        self.sponsors = sponsors.map(SponsorViewModel.init)
    }
}
