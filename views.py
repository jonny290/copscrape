from django.http import HttpResponse
from fayettevillains.models import Incidents
from django.template import RequestContext, loader
from django import forms
from django.shortcuts import render_to_response
from gmapi import maps
from gmapi.forms.widgets import GoogleMap

def hello(request):

    html = "<html><body>"


    results = Incidents.objects.order_by("-date")[0:30]
    html +="<h1>Fayettevillains last dispatches</h1>" 
    html +="<br> <br>"
    for p in results:
        html += str(p.date) + "  " + p.desc + "  " + p.add + "<br>"
    html += "</body></html>"
    return HttpResponse(html)



class MapForm(forms.Form):
    map = forms.Field(widget=GoogleMap(attrs={'width':450, 'height':600}))


def index(request):
    gmap = maps.Map(opts = {
        'center': maps.LatLng(36.0764, -94.1608),
        'mapTypeId': maps.MapTypeId.ROADMAP,
        'zoom': 13,
        'mapTypeControlOptions': {
             'style': maps.MapTypeControlStyle.DROPDOWN_MENU
        },
    })
    results = Incidents.objects.order_by("-date")[0:30]
    tweetdiv = ''
    tweetlist = []
    for q in results:
        tweet = '<tr><td class="address" rowspan="2">' + q.add + '</td><td class="crime">' + q.desc + '</td></tr><tr><td class="time"> ' + str(q.date) + '</td></tr>'
        #tweetdiv += tweet + ''
        tweetlist.append(tweet)
        if q.lat != 0 and q.lon != 0:
           marker = maps.Marker(opts = {
           'map': gmap,
           'position': maps.LatLng(q.lat, q.lon),
           })
           maps.event.addListener(marker, 'mouseover', 'myobj.markerOver')
           maps.event.addListener(marker, 'mouseout', 'myobj.markerOut')
           info = maps.InfoWindow({
               'content': q.desc + '' + q.add,
               'disableAutoPan': True
           })
           info.open(gmap, marker)
    context = {'form': MapForm(initial={'map': gmap}), 'tweet' : tweetlist}
    return render_to_response('fayettevillains/index.html', context)
