class searchResult extends React.createClass {
  render() {
    return (
      <tr className="searchResult">
        <td><input type="checkbox" class="sel-item" name="item-0" value="51f8e290-1a1e-481b-b99c-f8509f98f605" checked=""></td>
        <td><a class="facet-item" data-facettype="accessionnumber" data-sort="2000.0261">2000.0261</a></td>
        <td><a class="facet-item" data-facettype="determination">Viburnum trilobum Marshall</a></td>
        <td><a class="facet-item" data-facettype="family">ADOXACEAE</a></td>
        <td><a class="facet-item" data-facettype="gardenlocation"></a></td>
        <td><a class="facet-item" data-facettype="locality">Maine, U.S.A., North America</a></td>
        <td><a class="facet-item" data-facettype="collector">Clark, T.</a></td>
        <td><a class="facet-item" data-facettype="collectornumber">s.n.</a></td>
        <td><a class="facet-item" data-facettype="rare">no</a></td>
        <td><a class="facet-item" data-facettype="deadflag">yes</a></td>
        <td><a class="facet-item" data-facettype="flowercolor"></a></td>
      </tr>
    )
  }
}

class SearchResults extends React.Component {
  render() {
    return (
      <div id="results">
        <table cellspace="1" id="resultsListing" class="tablesorter-blue">
          <thead>
            <tr>
              <th></th>
              <th>Accession Number</th>
              <th>Scientific Name</th>
              <th>Family</th>
              <th>Garden Location</th>
              <th>Geographic Place Name</th>
              <th>Collector</th>
              <th>Collector Number</th>
              <th>Rare?</th>
              <th>Dead?</th>
              <th>Flower Color</th>
            </tr>
          </thead>
          <tbody>
            <searchResult />
          </tbody>
        </table>
      </div>
    );
  }
}

module.exports = SearchResults;