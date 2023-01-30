# Paginator

An abstract paginator, thoroughly tested.

In order to use, implement the `FetchService` protocol:

```
public protocol FetchService {
	
	associatedtype Item: Comparable & Identifiable
	associatedtype Filter
	
	func fetch(
		count: Int,
		page: Int,
		filter: Filter?
	) async throws -> [Element]
}

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
