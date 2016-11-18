// class RadioButton extends React.Component {}
// class TextInput extends React.Component {}
// class Anchor extends React.Component {}
// class Checkbox extends React.Component {}
// class ResultsList extends React.Component {}
// class ResultsForm extends React.Component {}

class TextInput extends React.Component {
  constructor(props) {
    super(props);
    if ('defaultValue' in this.props) {
      this.state = {value: this.props.defaultValue};
    } else {
      this.state = {value: ''};      
    }
    this.handleChange = this.handleChange.bind(this);
  }
  
  handleChange(event) {
    if ('defaultValue' in this.props && Array.isArray(this.props.defaultValue)) {
      var nextValue = this.state.value.slice();
      nextValue[$(event.target).data('index')] = event.target.value;
      this.setState({value: nextValue});
    } else {
      this.setState({value: event.target.value});      
    }
  }
  
  render() {
    if (Array.isArray(this.state.value)) {
      var formInput = [];
      for (var i=0; i<this.state.value.length; i++) {
        if (i !== 0) {
          formInput.push(<br/>);
        }
        formInput.push(<input type="text" key={i} data-index={i}
          name={this.props.data.name} maxLength={this.props.data.parameter}
          value={this.state.value[i]} onChange={this.handleChange}/>);
      }
    } else {
      var formInput = (<input type="text" 
        name={this.props.data.name} maxLength={this.props.data.parameter} 
        value={this.state.value} onChange={this.handleChange}/>)
    }
    return (
      <td>{formInput}</td>      
    );
  }
}

class Dropdown extends React.Component {
  constructor(props) {
    super(props);
    this.state = {value: 'default'};
    this.handleChange = this.handleChange.bind(this);
  }
  handleChange(event) {
    this.setState({value: event.target.value});
  }
  render() {
    return (
      <td>
      <select name={this.props.data.name}
        value={this.state.value} onChange={this.handleChange}>
        <option value="default">Select</option>
        {this.props.data.parameter.map((p, i) => {
          return (<option key={i} value={p[1]}>{p[0]}</option>);
        })}
      </select>
      </td>
    );
  }
}

class DateField extends React.Component {
  render() {
    return (
      <td>
        <input type="text" className="datepicker" id={this.props.data.name}
          name={this.props.data.name} value={this.props.data.value}/>
      </td>
    );
  }
}

class Button extends React.Component {
  render() {
    return (
      <td>
        <button type="button" data-parameter={this.props.data.parameter} name={this.props.data.name}
          className="prettyBtn">{this.props.data.label}</button>
      </td>
    );
  }
}

class SubmitButton extends React.Component {
  render() {
    return (
      <td>
      <button id="submitBtn" type="submit" value={this.props.data.parameter} name="state"
        className="prettyBtn" style={{color: "darkred"}}>{this.props.data.label}</button>
      </td>
    );
  }
}

class ResetButton extends React.Component {
  render() {
    return (
      <td>
      <button type="button" id="search-reset" className="prettyBtn">
        Reset
      </button>
      </td>
    );
  }
}

class FormField extends React.Component {
  render() {
    switch(this.props.data.type) {
      case 'dropdown':
        return (<Dropdown data={this.props.data}/>);
        break;
      case 'text':
        if ('defaultValue' in this.props) {
          return (<TextInput data={this.props.data} defaultValue={this.props.defaultValue}/>);
        }
        return (<TextInput data={this.props.data}/>);
        break;
      case 'integer':
      case 'string':
        return (<td>{this.props.defaultValue}</td>);
        break;
      case 'hidden':
        return (<td><input type="hidden" value={this.props.defaultValue}/></td>);
        break;
      case 'date':
        return (<DateField data={this.props.data}/>);
        break;
      case 'button':
        if (this.props.data.name !== 'start' && this.props.data.name !== 'reset') {
          return (<Button data={this.props.data}/>);
        } else {
          console.log('error rendering');
          console.log(this.props.data);
          return (<td></td>);
        }
        break;
      default:
        console.log('error rendering');
        console.log(this.props.data);
        return (<td></td>);
    }
  }
}

class SearchForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {applayout: [], resultlayout: {}};
    this.handleSubmit = this.handleSubmit.bind(this);
  }
  handleSubmit(event) {
    event.preventDefault();
    var submission = $(event.target).serializeArray();
    submission.push({name: 'state', value: $('#submitBtn').val()});
    submission.push({name: 'appname', value: this.props.appName});
    
    $.ajax({
      url: this.props.url,
      data: submission,
      dataType: 'json',
      cache: false,
      success: function(data) {
        console.log(data);
        this.setState({resultlayout: data});
      }.bind(this),
      error: function(xhr, status, err) {
        console.error(this.props.url, status, err.toString());
      }.bind(this)
    });
  }
  componentDidMount() {
    $.ajax({
      url: this.props.url,
      data: {
        state: this.props.appState,
        appname: this.props.appName
      },
      dataType: 'json', 
      cache: false,
      success: function(data) {
        this.setState({applayout: data.applayout});
      }.bind(this),
      error: function(xhr, status, err) {
        console.error(this.props.url, status, err.toString());
      }.bind(this)
    });
  }
  render() {
    var data = this.state.applayout.filter((cellLayout) => {
      return cellLayout.type !== 'button';
    });
    data.sort((a,b) => { 
      return (a.row-b.row !== 0 ? a.row-b.row : a.column-b.column); 
    });
    
    var rowCount = data.length > 0 ? data[0].row : 0;
    var cells = [];
    var rows = [];
    for (var i=0; i<data.length; i++) {
      //when the row changes push the current set of cells 
      //into a <tr> to `rows`, reset `cells`, and increment rowCount
      if ('row' in data[i] && data[i].row !== rowCount) {
        rows.push(<tr key={rowCount}>{cells}</tr>);
        cells = [];
        rowCount = data[i].row;
      }
      
      //in the case of buttons, the `label` property is used by the button
      //all other cases, though, `label` is displayed before the form field
      if ('label' in data[i] && data[i].type !== 'button') {
        var style = data[i].hasOwnProperty('style') ? data[i].style : {};
        cells.push (
          <td key={data[i].id + '_label'} style={style}>
            <label>{data[i].label}</label>
          </td>
        );        
      }
      
      cells.push(<FormField key={data[i].id + '_field'} data={data[i]}/>);

    }
    rows.push(<tr key={rowCount}>{cells}</tr>);
    cells = [];
    
    //force submit and reset buttons to be in their own row at the very end
    var submit = this.state.applayout.find((formItem) => { return formItem.name === 'start'; });
    var reset = this.state.applayout.find((formItem) => { return formItem.name === 'reset'; });
    if (submit) {
      cells.push(<SubmitButton key={submit.id + '_button'} data={submit}/>);
    } else if(data.length > 0) {
      console.log('error - no submit button specified, next state unknown');
    }
    if (reset) {
      cells.push(<Button key={reset.id + '_button'} data={reset}/>);
    } else {
      cells.push(<ResetButton key='reset'/>);
    }
    rows.push(<tr key={rowCount+1}>{cells}</tr>);
    
    var results = '';
    if (!$.isEmptyObject(this.state.resultlayout)) {
      results = (<ResultsForm data={this.state.resultlayout}/>);
    }
    
    return (
      <div>
        <form className="searchForm" onSubmit={this.handleSubmit}>
          <table><tbody>
          {rows}
          </tbody></table>
        </form>
        {results}
      </div>
    );
  }
}

class ResultsForm extends React.Component {
  constructor(props) {
    super(props);
    this.handleSubmit = this.handleSubmit.bind(this);
  }
  handleSubmit(event) {
    event.preventDefault();
    var rows = $(event.target).find('tr');
    //first row is header elements
    rows.splice(0,1);
    //last row is submit buttons
    rows.splice((rows.length-1), 1);
    
    var items=[];
    for (var i=0; i<rows.length; i++) {
      var row = {csid: $(rows[i]).data('csid'), cells: []};
      
      var cells = $(rows[i]).find('td');
      var itemValues = [];
      
      for (var j=0; j<cells.length; j++) {
        var isInputCell = false;
        var cellValues = [];

        var cellInputElements = $(cells[j]).find(':input');
        if (cellInputElements.length > 1) {
          isInputCell = true;
          cellValues = [];
          for (var k=0; k<cellInputElements.length; k++) {
            cellValues.push($(cellInputElements[k]).val());
          }
        } else if (cellInputElements.length === 1) {
          isInputCell = true;
          cellValues = $(cellInputElements[0]).val();
        } 
        
        if(isInputCell) {
          itemValues.push(cellValues);
        }
      }
      
      row.cells = itemValues;
      items.push(row);
    }
    console.log(items);
    // console.log($(event.target).serializeArray());
  }
  render() {
    var data = this.props.data;
    // var data = {
    //       "items": [["5-13875", "Mask", "1", "Nigeria; Igbo", ["5.3 Objects relating to the Secular and Quasi-religious Rites, Pageants, and Drama"], ["Igbo", "Igbo Too"]], ["2-4599", "Mask", "1", "Alaska", ["5.3 Objects relating to the Secular and Quasi-religious Rites, Pageants, and Drama"], ["Alaskan Eskimo"]], ["3-15571", "Mask", "1", "Coban, Guatemala", "", ""], ["3-28558", "Mask", "1", "", ["5.3 Objects relating to the Secular and Quasi-religious Rites, Pageants, and Drama"], ""], ["5-15547", "Mask", "1", "Tanzania; Bantu, Makonde", ["5.0 Use not specified (Ritual, Pageantry, and Recreation)"], ["Bantu"]], ["3-29175", "mask", "1", "", "", ""], ["2-21406", "Mask", "1", "Alaska; Seward Peninsula; Lopp Lagoon", "", ""], ["18-1652", "mask", "1", "", "", ""], ["16-18199", "Mask", "1", "", "", ""], ["2-66926", "Mask", "1", "Canada; British Columbia", "", ["Kwakwaka'wakw"]], ["5-10200", "mask", "1", "Africa; Nigeria; Igana; Yoruba", ["5.3 Objects relating to the Secular and Quasi-religious Rites, Pageants, and Drama"], ["Yoruba"]], ["5-16206", "mask", "1", "Africa; Congo (Ba Lega) Wa Rega  ", "", ["Ba Lega"]], ["9-10924", "mask", "1", "India, Rajasthan, Udaipur district", ["5.3 Objects relating to the Secular and Quasi-religious Rites, Pageants, and Drama"], ["Indian"]], ["2-2863", "Mask", "1", "Alaska; Lower Yukon", "", ["Alaskan Eskimo"]], ["3-30481", "mask", "1", "", "", ""], ["5-16020", "Mask", "1", "Nigeria; Udi; Ibo", ["5.3 Objects relating to the Secular and Quasi-religious Rites, Pageants, and Drama"], ["Ibo"]], ["9-18265", "mask", "1", "", ["5.1 Religion and Divination: Objects and garb associated with practices reflecting submission, devotion, obedience, and service to supernatural agencies"], ""], ["11-37310", "mask", "1", "", "", ["Abelam"]], ["2-10044", "Mask", "1", "; Northwest Coast", "", ["Nootka"]], ["5-15579", "mask", "1", "Tanzania; Bantu, Makonde", ["5.0 Use not specified (Ritual, Pageantry, and Recreation)"], ["Bantu"]], ["5-3298", "Mask", "1", "Africa; Mali; Senufo Tribe", "", ["Senufo"]], ["2-40812", "Mask", "1", "Alaska; Brooks Range; Anaktuvuk Pass", "", ["Nunamiut Eskimo"]], ["2-30963", "Mask", "1", "Alaska; Point Hope", "", ["Alaskan Eskimo"]], ["5-3319", "Mask", "1", "Africa; Ivory Coast; Guro tribe", "", ["Guro"]], ["5-16170a", "mask", "1", "", "", ["Yoruba"]], ["11-37699", "mask", "1", "", ["5.1 Religion and Divination: Objects and garb associated with practices reflecting submission, devotion, obedience, and service to supernatural agencies"], ["@New Guinea (Papua Island)"]], ["5-15789", "mask", "1", "West Africa; Ivory Coast; Guro", ["5.7 Gifts, Novelties, Models, \"Fakes,\" and Reproductions (excluding currency) and Commemorative Medals"], ["Guro"]], ["5-13480", "Mask", "1", "West Africa, Mali/ Ivory Coast/ Upper Volta, Senufo;  Collected at Abidian", ["5.3 Objects relating to the Secular and Quasi-religious Rites, Pageants, and Drama"], ["Senufo"]], ["9-2030", "mask", "2", "", ["5.7 Gifts, Novelties, Models, \"Fakes,\" and Reproductions (excluding currency) and Commemorative Medals"], ""], ["5-16176", "mask", "1", "West Africa; Nigeria; Ibo", "", ["Ibo", "Igbo"]], ["11-42491", "mask", "1", "", ["5.1 Religion and Divination: Objects and garb associated with practices reflecting submission, devotion, obedience, and service to supernatural agencies"], ["@New Guinea (Papua Island)"]], ["5-13864", "Mask", "1", "West Africa, Liberia, Bassa;  Purchased from E.M. Buchholz", ["5.3 Objects relating to the Secular and Quasi-religious Rites, Pageants, and Drama"], ["Bassa"]], ["5-16220", "mask", "1", "West Africa; Nigeria; Yoruba", "", ["Yoruba"]], ["2-6476", "Mask", "1", "Alaska; St. Michael", ["5.3 Objects relating to the Secular and Quasi-religious Rites, Pageants, and Drama"], ["Alaskan Eskimo"]], ["2-6473", "Mask", "1", "Alaska; Pastolik", ["5.3 Objects relating to the Secular and Quasi-religious Rites, Pageants, and Drama"], ["Alaskan Eskimo"]], ["5-13574", "Mask", "1", "Liberia/Ivory Coast; Dan (Gio) attr. (WRB 1978)", ["5.1 Religion and Divination: Objects and garb associated with practices reflecting submission, devotion, obedience, and service to supernatural agencies"], ["Dan"]], ["2-59112", "Mask", "1", "Alaska; Brooks Range; Anaktuvuk Pass", "", ["Nunamiut Eskimo"]], ["5-3373", "Mask", "1", "Africa; Ivory Coast; Nuclear Mande; Mau.", "", ["Nuclear Mande"]], ["18-1516", "mask", "1", "", ["5.7 Gifts, Novelties, Models, \"Fakes,\" and Reproductions (excluding currency) and Commemorative Medals"], ["Malaysian"]], ["5-8651", "Mask", "1", "Faiyum", "", ""]], "applayout": [{"name": "review", "type": "button", "label": "Update Key Info", "parameter": "update", "id": 58}, {"name": "ob.museumnumber", "column": "", "type": "string", "label": "Museum #", "parameter": 100, "id": 135, "row": ""}, {"name": "ob.objectname", "column": "", "type": "text", "label": "Object name", "parameter": 140, "id": 136, "row": ""}, {"name": "count", "column": "", "type": "text", "label": "Count", "parameter": 40, "id": 137, "row": ""}, {"name": "fc.fieldcollectionplace", "column": "", "type": "text", "label": "Field Collection Place", "parameter": 150, "id": 138, "row": ""}, {"name": "culturalgroup", "column": "", "type": "text", "label": "Cultural Group", "parameter": 150, "id": 139, "row": ""}, {"name": "ethnographicfilecode", "column": "", "type": "text", "label": "Ethnographic File Code", "parameter": 150, "id": 140, "row": ""}], "numberofitems": 40, "appname": "keyinfo"
    // };

    // data.items = data.items.map((item, index) => {
    //   return {"csid": index, "cells": item};
    // });
    
    // everything above this line gets replaced once API is established
    // -----------------------------------------------------------------
    //exclude all buttons in applayout from the row layout
    var rowlayout = data.applayout.filter((cellLayout) => {
      return cellLayout.type !== 'button';
    });
    
    var header = rowlayout.map((cell) => {
      return (<th key={cell.id}>{cell.label}</th>);
    });
    
    var rows = data.items.map((item) => {
      var cells = [];
      for (var i=0; i<rowlayout.length; i++) {
        cells.push(<FormField key={item.csid + '_' + rowlayout[i].id} data={rowlayout[i]} defaultValue={item.cells[i]}/>);
      }
      return (<tr data-csid={item.csid} key={item.csid}>{cells}</tr>);
    });
    
    var submitButtons = [];
    var submit = this.props.data.applayout.find((formItem) => { return formItem.name === 'review'; });
    var reset = this.props.data.applayout.find((formItem) => { return formItem.name === 'reset'; });
    if (submit) {
      submitButtons.push(<SubmitButton key={submit.id + '_button'} data={submit}/>);
    } else if(data.length > 0) {
      console.log('error - no submit button specified, next state unknown');
    }
    if (reset) {
      submitButtons.push(<Button key={reset.id + '_button'} data={reset}/>);
    } else {
      submitButtons.push(<ResetButton key='reset'/>);
    }
    submitButtons = (<table><tbody><tr>{submitButtons}</tr></tbody></table>);
    
    return (
      <form className="resultsForm" onSubmit={this.handleSubmit}>
      <table>
        <thead><tr>{header}</tr></thead>
        <tbody>{rows}</tbody>
      </table>
      <hr/>
      {data.numberofitems} items listed.
      {submitButtons}
      </form>
    )
  }
}

ReactDOM.render(
  <SearchForm url="toolbox/json/" appState='start' appName='objinfo'/>,
  document.getElementById('searchForm')
);

// ReactDOM.render(
//   <ResultsForm />, document.getElementById('resultsForm')
// );
