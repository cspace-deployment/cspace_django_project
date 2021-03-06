__author__ = 'amywieliczka, jblowe'

from django.conf.urls import patterns, url
from search import views

urlpatterns = patterns('',
                       url(r'^/?$', views.direct, name='direct'),
                       url(r'^search/$', views.search, name='search'),
                       url(r'^search/(?P<fieldfile>[\w-]+)$', views.loadNewFields, name='loadNewFields'),
                       url(r'^results/$', views.retrieveResults, name='retrieveResults'),
                       url(r'^json/$', views.retrieveJSON, name='retrieveJSON'),
                       url(r'^json/facet/$', views.facetJSON, name='facetJSON'),
                       url(r'^json-entry/$', views.JSONentry, name='JSONentry'),
                       url(r'^bmapper/$', views.bmapper, name='bmapper'),
                       url(r'^statistics/$', views.statistics, name='statistics'),
                       url(r'^dispatch/$', views.dispatch, name='dispatch'),
                       #url(r'^csv/$', views.csv, name='csv'),
                       #url(r'^pdf/$', views.pdf, name='pdf'),
                       url(r'^gmapper/$', views.gmapper, name='gmapper'),
                       )
