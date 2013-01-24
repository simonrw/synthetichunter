#!/usr/bin/env python
# -*- coding: utf-8 -*-

'''
Usage:
    GenerateImages.py [options] <host> <port> <file>...

Options:
    -h, --help                  Show this help
'''

import pyfits
from docopt import docopt
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import pymongo
from functools import partial
import md5
from matplotlib.ticker import ScalarFormatter
from multiprocessing import Pool
from srw.constants import *
import os
from random import random

BASEDIR = os.path.dirname(__file__)
IMAGEDIR = os.path.join(BASEDIR, 'images')
FIGURESIZE = (8, 5)

def to_phase(t, epoch, period):
    return (t - epoch) / period

def next_mid_transit(hjd, epoch, period):
    '''
    Generates mid-transit points for a lightcurve
    '''
    # Get the first mid transit after the data starts
    start, end = hjd.min(), hjd.max()
    current = epoch

    # Rewind the `current` value to the first point enclosed by the data
    phase_min = to_phase(start, epoch, period)
    if phase_min < 0:
        phase_start = np.ceil(phase_min)
    else:
        phase_start = np.floor(phase_min)

    current = phase_start * period + epoch

    while current < end:
        yield current
        current += period

def generate_images(hjd, flux, period, epoch, twidth, outdir,
        out_base, detect_width=3):
    '''
    Generates images of any transits which have data within +-`detect_width
    * twidth` of the mid-transit point and render to `outdir`
    '''
    ii = 0
    out_names = []
    for t0 in next_mid_transit(hjd, epoch, period):
        # Indices for the in transit points
        ind = ((hjd >= t0 - detect_width * twidth) &
                (hjd <= t0 + detect_width * twidth))

        if ind.any():
            slice_hjd = hjd[ind] - t0
            slice_flux = flux[ind]

            plt.plot(slice_hjd, slice_flux, 'r.', ms=5)
            plt.axvline(0)
            plt.axvline(-twidth / 2.)
            plt.axvline(twidth / 2.)
            plt.xlim(-detect_width * twidth, detect_width * twidth)
            plt.ylim(0.1, -0.1)
            plt.xlabel(r'HJD - {0}'.format(t0))
            out_name = os.path.join(outdir,
                out_base + '_' + str(ii) + '.png')
            plt.savefig(out_name)
            plt.close()
            ii += 1
            out_names.append(os.path.realpath(out_name))

    return out_names


def analyse_data_object(out_name_base, lightcurves_data, period, epoch, width):
    '''
    Given the lightcurve data, plot the object's transits
    '''
    hjd, mags = lightcurves_data
    return generate_images(hjd, mags, period, epoch, width,
            os.path.dirname(out_name_base), os.path.basename(out_name_base))






def bin_data(xdata, ydata, nbins, x_range=(-0.2, 0.8)):
    '''
    Bin the data into an integer number of bins
    '''
    xdata, ydata = [np.array(d) for d in (xdata, ydata)]
    inc = (x_range[1] - x_range[0]) / float(nbins)

    ind = np.argsort(xdata)
    xdata, ydata = [data[ind] for data in [xdata, ydata]]

    bx, by, be = [], [], []
    for i in xrange(nbins - 1):
        l = x_range[0] + i * inc
        h = l + inc

        ind = (xdata >= l) & (xdata < h)
        bx.append(l)

        inbin_y = ydata[ind]

        try:
            bin_av = np.average(inbin_y)
            by.append(bin_av)
            be.append(1.25 * np.median(np.abs(inbin_y - np.median(inbin_y))) /
                    np.sqrt(inbin_y.size))
        except ZeroDivisionError:
            by.append(0)
            be.append(0)

    return [np.array(d) for d in [bx, by, be]]

def match(a, b, toler=0.01):
    '''
    Fuzzy matching function
    '''
    return (np.abs(a - b) / b) < toler

def wd2jd(wd):
    jd_ref=2453005.5
    return (wd / secondsInDay) + jd_ref

def mcmc_wd2jd(wd):
    jd_ref=2450000.0
    return (wd / secondsInDay) + jd_ref



def hash_object(filename, obj_id):
    '''
    Generate an object hash based on the filename and object id. This should be
    unique per object and match an image.
    '''
    return md5.new(os.path.basename(filename) + ':' + obj_id).hexdigest()

def image_filename(filename, obj_id, prefix, suffix='.png'):
    return os.path.join(IMAGEDIR, prefix + hash_object(filename, obj_id) +
            suffix)

lc_filename = partial(image_filename, prefix='lc_')
pgram_filename = partial(image_filename, prefix='pg_')
phase_filename = partial(image_filename, prefix='phase_')
tr_filename_base = partial(image_filename, prefix='tr_', suffix='')

def analyse_file(filename, db):
    print "Analysing [{0}]".format(filename)
    with pyfits.open(filename, memmap=True) as infile:
        # Need to perform selection cuts
        candidates = infile['candidates'].data
        catalogue = infile['catalogue'].data

        obj_id = candidates.field('obj_id')
        ranks = candidates.field('rank')
        cat_index = (candidates.field("cat_idx") - 1)
        sde = candidates.field("sde")
        ntrans = candidates.field("num_transits")
        delta_chisq = candidates.field("delta_chisq")
        prob_rp = candidates.field("mcmc_prp")
        sn_red = candidates.field("sn_red")
        sn_ellipse = candidates.field("sn_ellipse")
        mcmc_dchisq_mr = candidates.field("mcmc_dchisq_mr")
        clump_idx = candidates.field("clump_indx")
        mcmc_period = candidates.field("mcmc_period")
        mcmc_width = candidates.field('mcmc_width')
        mcmc_epoch = candidates.field('mcmc_epoch')
        mcmc_depth = candidates.field('mcmc_depth')

        lc_index = candidates.field('lc_idx') - 1
        pgram_index = candidates.field('pg_idx') - 1


        fake_period = catalogue.field('fake_period') / secondsInDay
        fake_depth = catalogue.field('fake_depth')
        fake_width = catalogue.field('fake_width') / 3600.
        fake_radius = catalogue.field('fake_rp') / rJup
        fake_rstar = catalogue.field('fake_rs') / rSun
        fake_a = catalogue.field('fake_a') / AU
        fake_epoch = wd2jd(catalogue.field('fake_epoch'))
        fake_i = np.degrees(catalogue.field('fake_i'))
        vmag = catalogue.field('vmag')
        teff_jh = catalogue.field('teff_jh')

        mcmc_radius = candidates.field('mcmc_rplanet')
        mcmc_rstar = candidates.field('mcmc_rstar')
        orion_period = candidates.field('period')
        orion_epoch = candidates.field('epoch')
        orion_depth = candidates.field('depth')




        ind = np.array([True if 'SWASP' not in name else False
            for name in obj_id])
        ind &= (ranks == 1)

        # Orion cuts
        ind &= (sde > 6.)
        ind &= (ntrans > 3.)
        ind &= (delta_chisq < -40.)

        # MCMC cuts
        ind &= (prob_rp > 0.1)
        ind &= (sn_red < -6.)
        ind &= (sn_ellipse < 6.)
        ind &= (mcmc_dchisq_mr < 7.)
        ind &= (clump_idx < 0.25)

        # Periodogram data
        pgram_period = infile['periods'].data.field('period')[0] / secondsInDay
        pgram_dchisq = infile['periodograms'].data.field('chisq')

        print "Data read"

        collection = db.objects

        all_objects = []

        if ind.any():
            objects = obj_id[ind]
            p_objects = infile['periodograms'].data.field('obj_id')[pgram_index[ind]]

            lightcurves_hdu = infile['lightcurves'].data
            hjd = lightcurves_hdu.field('hjd')
            mag = lightcurves_hdu.field('mag')
            mag_err = lightcurves_hdu.field('mag_err')

            assert objects.size == np.arange(obj_id.size)[ind].size

            for obj_id, p_obj_id, index in zip(objects, p_objects,
                    np.arange(obj_id.size)[ind]):

                assert obj_id == p_obj_id

                # Convenience function for accessing the mcmc values
                mcmc_val = lambda arr: float(arr[index])
                cat_val = lambda arr: float(arr[mcmc_val(cat_index)])

                # Perform an exclusion cut on the period
                if cat_val(fake_period) < 0.35):
                    print 'Skipping object with period of [0]'.format(
                            cat_val(fake_period))
                    continue

                #pgram_data = pgram_dchisq[pgram_index[ind][pmatchind]]
                pgram_data = pgram_dchisq[mcmc_val(pgram_index)]

                matching = match(mcmc_val(orion_period) / secondsInDay,
                        cat_val(fake_period))

                # Generate the periodogram
                plt.figure(figsize=FIGURESIZE)
                plt.plot(pgram_period, pgram_data, 'k-')
                plt.xlabel(r'Orbital period / days')
                plt.ylabel(r'$\Delta \chi^2$')
                plt.axvline(mcmc_val(orion_period) / secondsInDay, zorder=-10)
                plt.savefig(pgram_filename(filename, obj_id))
                plt.close()

                # Generate the lightcurve
                object_hjd = hjd[mcmc_val(lc_index)].astype(float)
                object_mag = mag[mcmc_val(lc_index)].astype(float)

                # Convert to jd
                object_hjd = wd2jd(object_hjd)
                epoch_val = wd2jd(float(mcmc_val(orion_epoch)))
                period_val = mcmc_val(orion_period) / secondsInDay


                phase = (object_hjd - epoch_val) / period_val
                phase[phase < 0] += 1.0
                phase = phase % 1
                phase[phase > 0.8] -= 1.0

                bin_x, bin_y, bin_e = bin_data(phase, object_mag, 150)

                plt.figure(figsize=FIGURESIZE)
                plt.plot(phase, object_mag, 'k.', ms=4, color='#aaaaaa')
                plt.errorbar(bin_x, bin_y, bin_e, ls='None')
                plt.plot(bin_x, bin_y, 'ro', ms=5, mec='k')
                plt.xlim(-0.2, 0.8)
                plt.xlabel(r'Orbital phase')
                plt.ylabel(r'$\Delta \mathrm{mag}$')
                plt.ylim(plt.ylim()[::-1])
                plt.savefig(lc_filename(filename, obj_id))
                plt.close()

                # Plot the parameter space data
                #plt.figure(figsize=FIGURESIZE)
                #plt.axvline(cat_val(fake_period), color='r')
                #plt.axhline(cat_val(fake_radius), color='r')
                #plt.axvline(mcmc_val(mcmc_period), color='g')
                #plt.axhline(mcmc_val(mcmc_radius), color='g')
                #plt.plot([cat_val(fake_period), ], [cat_val(fake_radius), ],
                        #'ro', ms=5, mec='k')
                #plt.plot([mcmc_val(mcmc_period), ], [mcmc_val(mcmc_radius), ],
                        #'go', ms=5, mec='k')
                #plt.yscale('log')
                #plt.xscale('log')
                #plt.xlim(0.1, 10)
                #plt.ylim(0.1, 6)
                ##plt.gca().xaxis.set_major_formatter(ScalarFormatter())
                ##plt.gca().yaxis.set_major_formatter(ScalarFormatter())
                #plt.xticks([0.1, 0.5, 1, 2, 5, 10], map(str, [0.1, 0.5, 1, 2, 5, 10]))
                #plt.yticks([0.1, 0.5, 1, 2, 5], map(str, [0.1, 0.5, 1, 2, 5]))
                #plt.grid(True, which='both')
                #plt.xlabel(r'Orbital period')
                #plt.ylabel(r'Planetary radius')
                #plt.savefig(phase_filename(filename, obj_id))
                #plt.close()

                # Generate the individual transit images
                tr_image_names = analyse_data_object(
                        tr_filename_base(filename, obj_id),
                        [wd2jd(object_hjd), object_mag],
                        mcmc_val(orion_period),
                        2450000.0 + mcmc_val(orion_epoch),
                        mcmc_val(mcmc_width),
                        )

                collection.insert({
                #all_objects.append({
                    'obj_id': obj_id,
                    'random': random(),
                    'file_info': {
                        'pg_filename': os.path.realpath(pgram_filename(filename,
                            obj_id)),
                        'lc_filename': os.path.realpath(lc_filename(filename, obj_id)),
                        'phase_filename': os.path.realpath(phase_filename(filename, obj_id)),
                        'data_filename': os.path.realpath(filename),
                        'tr_filenames': tr_image_names,
                    },
                    'object_type': 'synthetic' if matching else 'other',
                    #'plot_data': {
                        #'pgram': {
                            #'x': list(pgram_period),
                            #'y': list(pgram_data),
                            #},
                        #'lc': {
                            #'x': list(phase),
                            #'y': list(object_mag),
                            #},
                    #},
                    'object_info': {
                        'obj_id': obj_id,
                        'input': {
                            'radius': cat_val(fake_radius),
                            'epoch': cat_val(fake_epoch),
                            'i': cat_val(fake_i),
                            'a': cat_val(fake_a),
                            'rstar': cat_val(fake_rstar),
                            'width': cat_val(fake_width),
                            'depth': cat_val(fake_depth),
                            'period': cat_val(fake_period)
                            },
                        'orion': {
                            'sde': mcmc_val(sde),
                            'ntrans': int(mcmc_val(ntrans)),
                            'depth': -mcmc_val(orion_depth),
                            'delta_chisq': mcmc_val(delta_chisq),
                            'period': mcmc_val(orion_period) / secondsInDay,
                            'vmag': cat_val(vmag),
                            'teff': cat_val(teff_jh),
                            },
                        'mcmc': {
                            'period': mcmc_val(mcmc_period),
                            #'epoch': 2450000.0 + float(mcmc_val(mcmc_epoch)),
                            'prob_rp': mcmc_val(prob_rp),
                            'sn_red': mcmc_val(sn_red),
                            'sn_ellipse': mcmc_val(sn_ellipse),
                            'dchisq_mr': mcmc_val(mcmc_dchisq_mr),
                            'clump_idx': mcmc_val(clump_idx),
                            'radius': mcmc_val(mcmc_radius),
                            'rstar': mcmc_val(mcmc_rstar),
                            'depth': mcmc_val(mcmc_depth),
                            },
                        },
                    'user_info': [],
                    })

                #if len(all_objects) >= 10:
                    #print "Uploading"
                    #collection.insert(all_objects)
                    #all_objects = []



        else:
            print "No matches found"




def main(args):

    #hostname = 'db.circularspace.co.uk'
    #port = 26017
    hostname = args['<host>']
    port = int(args['<port>'])

    print "Connecting to " + hostname + ':' + str(port)

    conn = pymongo.Connection(host=hostname, port=port)
    conn.hunter.objects.remove()

    if not os.path.isdir(os.path.join(BASEDIR, 'images')):
        os.makedirs(os.path.join(BASEDIR, 'images'))

    #pool = Pool(4)
    map(partial(analyse_file, db=conn.hunter), args['<file>'])

if __name__ == '__main__':
    main(docopt(__doc__))
