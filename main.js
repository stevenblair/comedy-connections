/**
 * Comedy-Connections
 *
 * Copyright (c) 2012 Steven Blair
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

var UsedData = jQuery.extend(true, {}, Data);     // make a copy of the master data source

function findShowsWithPerson(personName) {
    var mapPersonToShow = jlinq.from(Data.personToShow)
    .join(
        Data.person,
        "personAlias", 
        "personId",
        "id")
    .select(function(rec) {
        return {
            showId: rec.showId,
            name: rec.personAlias[0].name
        };
    });

    var listOfShows = jlinq.from(mapPersonToShow)
    .contains("name", personName)
    .join(
        Data.show,
        "showAlias",
        "showId",
        "id")
    .select(function(rec) {
        return {
            showId: rec.showAlias[0].id,
            showName: rec.showAlias[0].title
        };
    });

    return listOfShows;
}

function findShowsWithPersonId(personIdParam) {
    var listOfShows = jlinq.from(Data.personToShow)
    .equals("personId", personIdParam)
    .join(
        Data.show,
        "showAlias",
        "showId",
        "id")
    .select(function(rec) {
        return {
            //showId: rec.showAlias[0].id,
            showName: rec.showAlias[0].title
        };
    });

    return listOfShows;
}

// an alternative to findShowsWithPersonId(), which doesn't use jLinq and is much faster
function findShowsWithPersonIdFast(personIdParam) {
    var listOfShowsIds = [];
    var listOfShowsNames = [];
    for (var x in UsedData.personToShow) {
        if (UsedData.personToShow[x].personId == personIdParam) {
            listOfShowsIds.push(Data.personToShow[x].showId);
        }
    }

    for (var y in listOfShowsIds) {
        for (var z in UsedData.show) {
            if (UsedData.show[z].id == listOfShowsIds[y]) {
                listOfShowsNames.push({
                    id: UsedData.show[z].id,
                    showName: UsedData.show[z].title
                });
            }
        }
    }

    return listOfShowsNames;
}

function findPersonInShows(showName) {
    var mapShowToPerson = jlinq.from(Data.personToShow)
    .join(
        Data.show,
        "showAlias",
        "showId",
        "id")
    .select(function(rec) {
        return {
            personId: rec.personId,
            title: rec.showAlias[0].title
        };
    });

    var listOfPersons = jlinq.from(mapShowToPerson)
    .contains("title", showName)
    .join(
        Data.person,
        "personAlias",
        "personId",
        "id")
    .select(function(rec) {
        return {
            personId: rec.personAlias[0].id,
            personName: rec.personAlias[0].name
        };
    });

    return listOfPersons;
}

function filter() {
    var filterText = $("#filterText").val();
    var include = $("#filterModeInclude").is(":checked");
    var viewMode = $("#viewModePeople").is(":checked");
    UsedData.person = jlinq.from(Data.person);
    UsedData.show = jlinq.from(Data.show);

    if (filterText != '') {
        if (viewMode == true && include == true) {
            UsedData.person = UsedData.person.contains("name", filterText);
        }
        else if (viewMode == true && include == false) {
            UsedData.person = UsedData.person.not().contains("name", filterText);
        }

        if (viewMode == false && include == true) {
            UsedData.show = UsedData.show.contains("title", filterText);
        }
        else if (viewMode == false && include == false) {
            UsedData.show = UsedData.show.not().contains("title", filterText);
        }
    }

    UsedData.person = UsedData.person.select();
    UsedData.show = UsedData.show.select();
    
    // apply to visualisation
    var p = Processing.getInstanceById('ComedyConnections');
    if (p) {
        p.resetData();
        p.createGraph();
        p.setLayout();
    }
}

$(function() {$("#filterText").keyup(function(eventObject) {
        filter();
    });
    $("#filterMode").buttonset().change(function(eventObject) {
        filter();
    });
    $("#viewMode").buttonset().change(function(eventObject) {
        var p = Processing.getInstanceById('ComedyConnections');
        if (p) {
            p.toggleViewMode();
        }
        filter();
    });
    $("#arrangement").buttonset().click(function(eventObject) {
        var radioButtons = $("input:radio[name='arrangement']");
        var selectedIndex = radioButtons.index(radioButtons.filter(':checked'));

        var p = Processing.getInstanceById('ComedyConnections');
        if (p) {
            p.changeLayoutMode(selectedIndex);
        }
    });
});
