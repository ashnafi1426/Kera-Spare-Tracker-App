import * as locationsService from '../services/locations.service.js';

export async function listLocations(req, res, next) {
  try {
    const locations = await locationsService.listLocations(req.user.id);
    res.status(200).json({
      success: true,
      data: locations,
    });
  } catch (err) {
    next(err);
  }
}

export async function createLocation(req, res, next) {
  try {
    const location = await locationsService.createLocation(req.user.id, req.body);
    res.status(201).json({
      success: true,
      message: 'Location created successfully',
      data: location,
    });
  } catch (err) {
    next(err);
  }
}

export async function deleteLocation(req, res, next) {
  try {
    const result = await locationsService.deleteLocation(req.user.id, req.params.id);
    res.status(200).json({
      success: true,
      message: result.message,
    });
  } catch (err) {
    next(err);
  }
}
