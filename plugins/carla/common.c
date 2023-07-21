/*
 * Carla plugin for OBS
 * Copyright (C) 2023 Filipe Coelho <falktx@falktx.com>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifndef _WIN32
// needed for libdl stuff and strcasestr
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <dlfcn.h>
#include <limits.h>
#include <stdlib.h>
#endif

#include <CarlaUtils.h>

#include <obs-module.h>
#include <util/platform.h>

#include "common.h"

// ----------------------------------------------------------------------------

static char *module_path = NULL;

const char *get_carla_bin_path(void)
{
	if (module_path != NULL)
		return module_path;

	char *mpath;

	// check path of linked carla-utils library first
	const char *const utilspath = carla_get_library_folder();
	const size_t utilslen = strlen(utilspath);

	mpath = bmalloc(utilslen + 28);
	memcpy(mpath, utilspath, utilslen);
	memcpy(mpath + utilslen, CARLA_OS_SEP_STR "carla-discovery-native", 24);
#ifdef _WIN32
	memcpy(mpath + utilslen + 24, ".exe", 5);
#endif

	if (os_file_exists(mpath)) {
		mpath[utilslen] = '\0';
		module_path = mpath;
		return module_path;
	}

	free(mpath);

#ifndef _WIN32
	// check path of this OBS plugin as fallback
	Dl_info info;
	dladdr(get_carla_bin_path, &info);
	mpath = realpath(info.dli_fname, NULL);

	if (mpath == NULL)
		return NULL;

	// truncate to last separator
	char *lastsep = strrchr(mpath, '/');
	if (lastsep == NULL)
		goto free;
	*lastsep = '\0';

#ifdef __APPLE__
	// running as macOS app bundle, use its binary dir
	char *appbundlesep = strcasestr(mpath, "/PlugIns/" CARLA_MODULE_ID
					       ".plugin/Contents/MacOS");
	if (appbundlesep == NULL)
		goto free;
	strcpy(appbundlesep, "/MacOS");
#endif

	if (os_file_exists(mpath)) {
		module_path = bstrdup(mpath);
		free(mpath);
		return module_path;
	}

free:
	free(mpath);
#endif // !_WIN32

	return module_path;
}

void param_index_to_name(uint32_t index, char name[PARAM_NAME_SIZE])
{
	name[1] = '0' + ((index / 100) % 10);
	name[2] = '0' + ((index / 10) % 10);
	name[3] = '0' + ((index / 1) % 10);
}

void remove_all_props(obs_properties_t *props, obs_data_t *settings)
{
	obs_data_erase(settings, PROP_RELOAD_PLUGIN);
	obs_properties_remove_by_name(props, PROP_RELOAD_PLUGIN);

	obs_data_erase(settings, PROP_SHOW_GUI);
	obs_properties_remove_by_name(props, PROP_SHOW_GUI);

	obs_data_erase(settings, PROP_CHUNK);
	obs_properties_remove_by_name(props, PROP_CHUNK);

	obs_data_erase(settings, PROP_CUSTOM_DATA);
	obs_properties_remove_by_name(props, PROP_CUSTOM_DATA);

	char pname[PARAM_NAME_SIZE] = PARAM_NAME_INIT;

	for (uint32_t i = 0; i < MAX_PARAMS; ++i) {
		param_index_to_name(i, pname);
		obs_data_unset_default_value(settings, pname);
		obs_data_erase(settings, pname);
		obs_properties_remove_by_name(props, pname);
	}
}

void postpone_update_request(uint64_t *update_req)
{
	*update_req = os_gettime_ns();
}

void handle_update_request(obs_source_t *source, uint64_t *update_req)
{
	const uint64_t old_update_req = *update_req;

	if (old_update_req == 0)
		return;

	const uint64_t now = os_gettime_ns();

	// request in the future?
	if (now < old_update_req) {
		*update_req = now;
		return;
	}

	if (now - old_update_req >= 100000000ULL) // 100ms
	{
		*update_req = 0;
		signal_handler_signal(obs_source_get_signal_handler(source),
				      "update_properties", NULL);
	}
}

void obs_module_unload(void)
{
	bfree(module_path);
	module_path = NULL;
}

// ----------------------------------------------------------------------------
