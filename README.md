# Paginator

An abstract paginator, thoroughly tested.

In order to use, implement the `FetchService` protocol:

```
public protocol FetchService {
	
	/**
	 `Comparable` and `Identifiable` conformances are needed for `Paginator` to sort the items list after merge and resolve collisions.
	 
	 Comparable is to support sorting (by `>`). E.g., by date added / date updated / alphabetically by name etc.
	 Both Comparable and Identifiable are needed to resolve duplicates of the same element.
	 The element with the higher order is kept, and the one with the lower is discarded.
	 */
	associatedtype Item: Comparable & Identifiable
	
	/**
	 An optional filter containing any conditions whatsoever - provided and handled by the `FetchService` implementation.
	 */
	associatedtype Filter
	
	/**
	 The fetch request, pretty much self explanatory.
	 */
	func fetch(
		count: Int,
		page: Int,
		filter: Filter?
	) async throws -> [Item]
}
```

...and use the paginator view model as follows:
```
// initialize
fetchService = DummyFetchService()
viewModel = PaginatorVM(fetchService: fetchService)

// apply optional filter
viewModel.filter = DummyFilter(optionalFlag: true)

// notify about events from the view and enjoy the ride
viewModel.onViewDidAppear()
viewModel.onRefresh()
viewModel.onItemShown(item) // to start fetching the next page beforehand
```
